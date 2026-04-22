set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
KEYS_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
AGE_SECRET="$REPO_ROOT/secrets/machines/$MACHINE/age.key.yaml"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

echo "==> Connecting to $TARGET..."

echo "==> Booting target into NixOS via kexec ..."
KEXEC_SIZE=$(stat -c%s "$KEXEC_TARBALL")
pv --size "$KEXEC_SIZE" --name "  kexec" "$KEXEC_TARBALL" | \
  ssh "${SSH_OPTS[@]}" "$TARGET" "
    set -euo pipefail
    mkdir -p /tmp/kexec
    tar xzf - -C /tmp/kexec
    /tmp/kexec/kexec/run
  " || true

echo "==> kexec fired — waiting for SSH to return..."
sleep 10

ATTEMPTS=0
until ssh "${SSH_OPTS[@]}" -o ConnectTimeout=5 "$TARGET" true 2>/dev/null; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge 60 ]; then
    echo "==> ERROR: machine did not come back after 5 minutes"
    exit 1
  fi
  echo "  ... waiting for ssh ($ATTEMPTS/60)"
  sleep 5
done

echo "==> SSH is back. Verifying NixOS live environment..."
ATTEMPTS=0
until ssh "${SSH_OPTS[@]}" -o ConnectTimeout=5 "$TARGET" "test -f /etc/NIXOS" 2>/dev/null; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge 24 ]; then
    echo "==> ERROR: host is up but not in NixOS kexec environment after 2 minutes"
    exit 1
  fi
  echo "  ... waiting for /etc/NIXOS ($ATTEMPTS/24)"
  sleep 5
done
echo "==> Running in NixOS environment."

echo "==> Decrypting age key for $MACHINE..."
if [ ! -f "$AGE_SECRET" ]; then
  echo "ERROR: $AGE_SECRET not found — did you run init-sops-machine?"
  exit 1
fi
SOPS_AGE_KEY_FILE="$KEYS_FILE" \
  sops decrypt --input-type yaml --output-type binary \
    "$AGE_SECRET" > "$WORK_DIR/age.key"

echo "==> Building disko script for $MACHINE..."
DISKO_SCRIPT=$(nix build --no-link --print-out-paths \
  ".#nixosConfigurations.$MACHINE.config.system.build.diskoScript")

echo "==> Copying disko script to $TARGET..."
nix copy --no-check-sigs --to "ssh-ng://$TARGET" "$DISKO_SCRIPT"

echo "==> Running disko on $TARGET..."
ssh "${SSH_OPTS[@]}" "$TARGET" bash -c "
  set -euo pipefail
  echo '==> Available disks:' && ls /dev/disk/by-id/ || true
  '$DISKO_SCRIPT'
"

echo "==> Injecting age key into /mnt/etc/sops/age/keys.txt..."
ssh "${SSH_OPTS[@]}" "$TARGET" "mkdir -p /mnt/etc/sops/age && chmod 700 /mnt/etc/sops/age"
ssh "${SSH_OPTS[@]}" "$TARGET" "cat > /mnt/etc/sops/age/keys.txt && chmod 600 /mnt/etc/sops/age/keys.txt" \
  < "$WORK_DIR/age.key"

if [ "$BUILD_LOCALLY" -eq 1 ]; then
    echo "==> Building system for $MACHINE..."
    SYSTEM=$(nix build --no-link --print-out-paths \
      ".#nixosConfigurations.$MACHINE.config.system.build.toplevel")

    echo "==> Copying system closure to $TARGET..."
    nix copy --no-check-sigs --to "ssh-ng://$TARGET" "$SYSTEM"

    echo "==> Running nixos-install..."
    ssh "${SSH_OPTS[@]}" "$TARGET" nixos-install --system "$SYSTEM" --no-root-password --no-channel-copy
else
    echo "==> Copying flake source to $TARGET..."
    rsync -a --exclude='.git' --exclude='result' \
      "$REPO_ROOT/" "root@$TARGET:/tmp/orbital/"

    echo "==> Building and installing on $TARGET..."
    ssh "${SSH_OPTS[@]}" "$TARGET" \
      "nixos-install --no-root-password --no-channel-copy --flake '/tmp/orbital#\$MACHINE'"
fi

echo "==> Rebooting $TARGET..."
ssh "${SSH_OPTS[@]}" "$TARGET" reboot || true

echo ""
echo "==> Done! $MACHINE is installing and rebooting."
echo "    Wait for reboot and verify with:"
echo "      ssh root@${TARGET#root@}"
