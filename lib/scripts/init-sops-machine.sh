set -euo pipefail

MACHINE="${1:-}"
if [ -z "$MACHINE" ]; then
  echo "Usage: init-sops-machine <machine>"
  echo ""
  echo "Known machines:"
  for m in $KNOWN_MACHINES; do echo "  - $m"; done
  exit 1
fi

VALID=0
for m in $KNOWN_MACHINES; do
  if [ "$m" = "$MACHINE" ]; then VALID=1; break; fi
done
if [ "$VALID" -eq 0 ]; then
  echo "Unknown machine: $MACHINE"
  echo "Known machines: $KNOWN_MACHINES"
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SOPS_YAML="$REPO_ROOT/.sops.yaml"
KEYS_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
SECRETS_DIR="$REPO_ROOT/secrets/machines/$MACHINE"
SSH_DIR="$SECRETS_DIR/ssh"

AGE_PUB="$SECRETS_DIR/age.pub"
AGE_SECRET="$SECRETS_DIR/age.key.yaml"
SSH_PUB="$SSH_DIR/ssh_host_ed25519_key.pub"
SSH_SECRET="$SSH_DIR/ssh_host_ed25519_key.yaml"

mkdir -p "$SECRETS_DIR" "$SSH_DIR"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

if [ ! -f "$KEYS_FILE" ]; then
  echo "ERROR: No age key file found at $KEYS_FILE"
  echo "Generate one with: age-keygen -o $KEYS_FILE"
  exit 1
fi
ADMIN_AGE_KEY=$(grep -i 'public key:' "$KEYS_FILE" | awk '{print $NF}')
if [ -z "$ADMIN_AGE_KEY" ]; then
  echo "ERROR: Could not extract public key from $KEYS_FILE"
  echo "Expected a line like: # public key: age1..."
  exit 1
fi
echo "==> Admin age key: $ADMIN_AGE_KEY"

if [ -f "$AGE_PUB" ] && [ -f "$AGE_SECRET" ]; then
  echo "==> Age keypair already exists for $MACHINE, skipping."
else
  echo "==> Generating age keypair for $MACHINE..."
  age-keygen -o "$WORK_DIR/age.key" 2>"$WORK_DIR/age-keygen.out"
  MACHINE_AGE_PUB=$(grep -i 'public key:' "$WORK_DIR/age-keygen.out" | awk '{print $NF}')

  echo "$MACHINE_AGE_PUB" > "$AGE_PUB"
  echo "    Age public key: $MACHINE_AGE_PUB"

  echo "==> Encrypting age private key → $AGE_SECRET"
  SOPS_AGE_KEY_FILE="$KEYS_FILE" SOPS_CONFIG=/dev/null \
    sops encrypt --input-type binary --output-type yaml \
      --age "$ADMIN_AGE_KEY" \
      "$WORK_DIR/age.key" > "$AGE_SECRET"
  echo "    Done."
fi

MACHINE_AGE_PUB=$(cat "$AGE_PUB")

if [ -f "$SSH_PUB" ] && [ -f "$SSH_SECRET" ]; then
  echo "==> SSH host keypair already exists for $MACHINE, skipping."
else
  echo "==> Generating ed25519 SSH host keypair for $MACHINE..."
  ssh-keygen -t ed25519 -N "" -C "root@$MACHINE" \
    -f "$WORK_DIR/ssh_host_ed25519_key" > /dev/null

  cp "$WORK_DIR/ssh_host_ed25519_key.pub" "$SSH_PUB"
  echo "    SSH public key: $(cat "$SSH_PUB")"

  echo "==> Encrypting SSH host private key → $SSH_SECRET"
  SOPS_AGE_KEY_FILE="$KEYS_FILE" SOPS_CONFIG=/dev/null \
    sops encrypt --input-type binary --output-type yaml \
      --age "$ADMIN_AGE_KEY,$MACHINE_AGE_PUB" \
      "$WORK_DIR/ssh_host_ed25519_key" > "$SSH_SECRET"
  echo "    Done."
fi

if [ ! -f "$SOPS_YAML" ]; then
  echo "==> Creating $SOPS_YAML..."
  printf 'keys: []\ncreation_rules: []\n' > "$SOPS_YAML"
fi

if ! yq --exit-status ".keys[] | select(. == \"$ADMIN_AGE_KEY\")" "$SOPS_YAML" > /dev/null 2>&1; then
  yq -i ".keys += [\"$ADMIN_AGE_KEY\"]" "$SOPS_YAML"
  echo "==> Added admin key to .sops.yaml"
fi

if ! yq --exit-status ".keys[] | select(. == \"$MACHINE_AGE_PUB\")" "$SOPS_YAML" > /dev/null 2>&1; then
  yq -i ".keys += [\"$MACHINE_AGE_PUB\"]" "$SOPS_YAML"
  echo "==> Added machine age key to .sops.yaml"
fi

# age.key.yaml is admin-only — the machine already has its age key injected at install time
ADMIN_RULE="secrets/machines/$MACHINE/age\\.key\\.yaml"
if ! yq --exit-status ".creation_rules[] | select(.path_regex == \"$ADMIN_RULE\")" "$SOPS_YAML" > /dev/null 2>&1; then
  yq -i ".creation_rules += [{
    \"path_regex\": \"$ADMIN_RULE\",
    \"key_groups\": [{\"age\": [\"$ADMIN_AGE_KEY\"]}]
  }]" "$SOPS_YAML"
  echo "==> Added admin-only creation rule for age key"
fi

# all other machine secrets (including ssh host key) use admin + machine
MACHINE_RULE="secrets/machines/$MACHINE/.*"
if ! yq --exit-status ".creation_rules[] | select(.path_regex == \"$MACHINE_RULE\")" "$SOPS_YAML" > /dev/null 2>&1; then
  yq -i ".creation_rules += [{
    \"path_regex\": \"$MACHINE_RULE\",
    \"key_groups\": [{\"age\": [\"$ADMIN_AGE_KEY\", \"$MACHINE_AGE_PUB\"]}]
  }]" "$SOPS_YAML"
  echo "==> Added machine creation rule"
else
  yq -i "
    (.creation_rules[] | select(.path_regex == \"$MACHINE_RULE\")
      .key_groups[0].age) = [\"$ADMIN_AGE_KEY\", \"$MACHINE_AGE_PUB\"]
  " "$SOPS_YAML"
  echo "==> Updated machine creation rule"
fi

echo ""
echo "==> Done! Summary for $MACHINE:"
echo "    Age pubkey : $(cat "$AGE_PUB")"
echo "    SSH pubkey : $(cat "$SSH_PUB")"
echo ""
echo "    Files to commit:"
echo "      secrets/machines/$MACHINE/age.pub"
echo "      secrets/machines/$MACHINE/age.key.yaml"
echo "      secrets/machines/$MACHINE/ssh/ssh_host_ed25519_key.pub"
echo "      secrets/machines/$MACHINE/ssh/ssh_host_ed25519_key.yaml"
echo "      .sops.yaml"
echo ""
echo "    Next: nix run .#install-machine -- $MACHINE"
