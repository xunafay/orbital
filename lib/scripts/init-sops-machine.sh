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
SHARED_DIR="$REPO_ROOT/secrets/shared"
SSH_DIR="$SECRETS_DIR/ssh"

AGE_PUB="$SECRETS_DIR/age.pub"
AGE_SECRET="$SECRETS_DIR/age.key.yaml"
SSH_PUB="$SSH_DIR/ssh_host_ed25519_key.pub"
SSH_SECRET="$SSH_DIR/ssh_host_ed25519_key.yaml"
SHARED_PUB="$SHARED_DIR/shared.pub"
SHARED_SECRET="$SHARED_DIR/shared.key.yaml"

mkdir -p "$SECRETS_DIR" "$SSH_DIR" "$SHARED_DIR" "$(dirname "$SHARED_PUB")"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

if [ ! -f "$KEYS_FILE" ]; then
  echo "ERROR: No age key file found at $KEYS_FILE"
  exit 1
fi
ADMIN_AGE_KEY=$(grep -i 'public key:' "$KEYS_FILE" | awk '{print $NF}')
if [ -z "$ADMIN_AGE_KEY" ]; then
  echo "ERROR: Could not extract public key from $KEYS_FILE"
  exit 1
fi
echo "==> Admin age key: $ADMIN_AGE_KEY"

if [ -f "$SHARED_PUB" ] && [ -f "$SHARED_SECRET" ]; then
  echo "==> Shared age keypair already exists, skipping."
else
  echo "==> Generating shared age keypair..."
  age-keygen -o "$WORK_DIR/shared.key" 2>"$WORK_DIR/shared-keygen.out"
  SHARED_AGE_PUB=$(grep -i 'public key:' "$WORK_DIR/shared-keygen.out" | awk '{print $NF}')

  echo "$SHARED_AGE_PUB" > "$SHARED_PUB"
  echo "    Shared age public key: $SHARED_AGE_PUB"

  echo "==> Encrypting shared age private key → $SHARED_SECRET"
  SOPS_AGE_KEY_FILE="$KEYS_FILE" SOPS_CONFIG=/dev/null \
    sops encrypt --input-type binary --output-type yaml \
      --age "$ADMIN_AGE_KEY" \
      "$WORK_DIR/shared.key" > "$SHARED_SECRET"
  echo "    Done."
fi

SHARED_AGE_PUB=$(cat "$SHARED_PUB")

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
  printf 'keys: []\ncreation_rules: []\n' > "$SOPS_YAML"
fi

for key in "$ADMIN_AGE_KEY" "$MACHINE_AGE_PUB" "$SHARED_AGE_PUB"; do
  if ! yq --exit-status ".keys[] | select(. == \"$key\")" "$SOPS_YAML" > /dev/null 2>&1; then
    yq -i ".keys += [\"$key\"]" "$SOPS_YAML"
    echo "==> Added key to .sops.yaml: $key"
  fi
done

SHARED_RULE="secrets/shared/.*"
if ! yq --exit-status ".creation_rules[] | select(.path_regex == \"$SHARED_RULE\")" "$SOPS_YAML" > /dev/null 2>&1; then
  yq -i ".creation_rules += [{
    \"path_regex\": \"$SHARED_RULE\",
    \"key_groups\": [{\"age\": [\"$ADMIN_AGE_KEY\", \"$SHARED_AGE_PUB\"]}]
  }]" "$SOPS_YAML"
  echo "==> Added shared creation rule"
else
  yq -i "
    (.creation_rules[] | select(.path_regex == \"$SHARED_RULE\")
      .key_groups[0].age) = [\"$ADMIN_AGE_KEY\", \"$SHARED_AGE_PUB\"]
  " "$SOPS_YAML"
  echo "==> Updated shared creation rule"
fi

ADMIN_RULE="secrets/machines/$MACHINE/age\\.key\\.yaml"
if ! yq --exit-status ".creation_rules[] | select(.path_regex == \"$ADMIN_RULE\")" "$SOPS_YAML" > /dev/null 2>&1; then
  yq -i ".creation_rules += [{
    \"path_regex\": \"$ADMIN_RULE\",
    \"key_groups\": [{\"age\": [\"$ADMIN_AGE_KEY\"]}]
  }]" "$SOPS_YAML"
  echo "==> Added admin-only creation rule for age key"
fi

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
echo "    Age pubkey    : $MACHINE_AGE_PUB"
echo "    Shared pubkey : $SHARED_AGE_PUB"
echo "    SSH pubkey    : $(cat "$SSH_PUB")"
echo ""
echo "    Files to commit:"
echo "      secrets/machines/$MACHINE/age.pub"
echo "      secrets/machines/$MACHINE/age.key.yaml"
echo "      secrets/machines/$MACHINE/ssh/ssh_host_ed25519_key.pub"
echo "      secrets/machines/$MACHINE/ssh/ssh_host_ed25519_key.yaml"
echo "      secrets/shared/shared-age-key/shared.key.yaml"
echo "      vars/shared/shared-age-key/shared.pub"
echo "      .sops.yaml"
echo ""
echo "    Next: nix run .#generate -- $MACHINE"
echo "    Then: nix run .#install-machine -- $MACHINE"
