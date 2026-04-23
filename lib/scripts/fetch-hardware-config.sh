set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
OUTPUT="$REPO_ROOT/machines/$MACHINE/facter.json"

echo "==> Connecting to $TARGET (port $PORT)..."
IS_NIXOS=0
if ssh -p "$PORT" -o ConnectTimeout=10 "$TARGET" "test -f /etc/NIXOS" 2>/dev/null; then
  if ssh -p "$PORT" -o ConnectTimeout=10 "$TARGET" "nixos-facter --version" 2>/dev/null; then
    IS_NIXOS=1
  fi
fi

if [ "$IS_NIXOS" -eq 0 ]; then
  echo "==> Target is not NixOS — booting into NixOS via kexec..."
  echo "    (disk is untouched, this is RAM only)"

  ssh -p "$PORT" "$TARGET" "
    set -euo pipefail
    mkdir -p /tmp/kexec
    tar xzf - -C /tmp/kexec
    /tmp/kexec/kexec/run
  " < "$KEXEC_TARBALL" || true

  echo "==> kexec fired — waiting for machine to come back up..."
  sleep 15

  ATTEMPTS=0
  until ssh \
    -p "$PORT" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=5 \
    "$TARGET" true 2>/dev/null
  do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ "$ATTEMPTS" -ge 36 ]; then
      echo "==> ERROR: machine did not come back after 3 minutes"
      exit 1
    fi
    echo "  ... waiting ($ATTEMPTS/36)"
    sleep 5
  done

  echo "==> Machine is back."
fi

echo "==> Running nixos-facter on $TARGET..."
ssh \
  -p "$PORT" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "$TARGET" "nixos-facter" > "$OUTPUT"

echo "==> Saved to $OUTPUT"
