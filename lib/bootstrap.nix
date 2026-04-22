# nix run .#fetch-hardware-config -- <machine>
{
  lib,
  inputs,
  inventory,
  pkgs,
}:
let
  kexecTarball = "${inputs.nixos-images.packages.x86_64-linux.kexec-installer-nixos-unstable}/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz";

  deployableHosts = lib.filterAttrs
    (_: machine: machine ? deploy && machine.deploy ? targetHost)
    inventory.machines;

  knownMachines = builtins.attrNames deployableHosts;

  # emit a shell case arm for each machine:
  #   mun) TARGET="root@1.2.3.4" ;;
  caseArms = lib.concatMapStringsSep "\n        " (name:
    let host = deployableHosts.${name}.deploy.targetHost;
    in "${name}) TARGET=\"${host}\" ;;"
  ) knownMachines;

  fetchHardwareConfig = pkgs.writeShellApplication {
    name = "fetch-hardware-config";
    runtimeInputs = with pkgs; [ openssh coreutils ];
    text = ''
      set -euo pipefail

      MACHINE="''${1:-}"
      if [ -z "$MACHINE" ]; then
        echo "Usage: fetch-hardware-config <machine>"
        echo ""
        echo "Known machines:"
        ${lib.concatMapStringsSep "\n" (n: "echo \"  - ${n}\"") knownMachines}
        exit 1
      fi

      TARGET=""
      case "$MACHINE" in
        ${caseArms}
        *)
          echo "Unknown machine: $MACHINE"
          echo "Known machines: ${lib.concatStringsSep ", " knownMachines}"
          exit 1
          ;;
      esac

      REPO_ROOT="$(git rev-parse --show-toplevel)"
      OUTPUT="$REPO_ROOT/machines/$MACHINE/facter.json"

      echo "==> Connecting to $TARGET..."
      IS_NIXOS=0
      if ssh -o ConnectTimeout=10 "$TARGET" "test -f /etc/NIXOS" 2>/dev/null; then
        IS_NIXOS=1
      fi

      if [ "$IS_NIXOS" -eq 0 ]; then
        echo "==> Target is not NixOS — booting into NixOS via kexec..."
        echo "    (disk is untouched, this is RAM only)"

        ssh "$TARGET" "
          set -euo pipefail
          mkdir -p /tmp/kexec
          tar xzf - -C /tmp/kexec
          /tmp/kexec/kexec/run
        " < "${kexecTarball}" || true

        echo "==> kexec fired — waiting for machine to come back up..."
        echo "    (SSH host key will change — using StrictHostKeyChecking=no for this session)"
        sleep 15

        ATTEMPTS=0
        until ssh \
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
          echo "  ... waiting ($ATTEMPTS/36, ''${ATTEMPTS}*5s elapsed)"
          sleep 5
        done

        echo "==> Machine is back."
      fi

      SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

      echo "==> Running nixos-facter on $TARGET..."
      ssh $SSH_OPTS "$TARGET" \
        "nixos-facter" \
        > "$OUTPUT"

      echo "==> Saved to $OUTPUT"
    '';
  };

in
{
  apps = {
    fetch-hardware-config = {
      type    = "app";
      program = "${fetchHardwareConfig}/bin/fetch-hardware-config";
    };
  };
}
