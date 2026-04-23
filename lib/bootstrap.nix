# nix run .#fetch-hardware-config -- <machine>
{ lib, inputs, inventory, pkgs }:
let
  kexecTarball = "${inputs.nixos-images.packages.x86_64-linux.kexec-installer-nixos-unstable}/nixos-kexec-installer-x86_64-linux.tar.gz";

  deployableHosts = lib.filterAttrs
    (_: machine: machine ? deploy && machine.deploy ? targetHost)
    inventory.machines;

  knownMachines = builtins.attrNames deployableHosts;

  caseArms = lib.concatMapStringsSep "\n        " (name:
    let
      host = deployableHosts.${name}.deploy.targetHost;
      port = deployableHosts.${name}.deploy.targetPort or 22;
    in "${name}) TARGET=${lib.escapeShellArg host} PORT=${lib.escapeShellArg (builtins.toString port)} ;;"
  ) knownMachines;

  fetchHardwareConfig = pkgs.writeShellApplication {
    name = "fetch-hardware-config";
    runtimeInputs = with pkgs; [ openssh coreutils ];
    text = ''
      MACHINE="''${1:-}"
      if [ -z "$MACHINE" ]; then
        echo "Usage: fetch-hardware-config <machine>"
        echo ""
        echo "Known machines:"
        for m in ${lib.concatStringsSep " " knownMachines}; do
          echo "  - $m"
        done
        exit 1
      fi

      TARGET=""
      PORT=""
      case "$MACHINE" in
        ${caseArms}
        *)
          echo "Unknown machine: $MACHINE"
          exit 1
          ;;
      esac

      KEXEC_TARBALL=${lib.escapeShellArg kexecTarball}
      export MACHINE TARGET PORT KEXEC_TARBALL

      ${builtins.readFile ./scripts/fetch-hardware-config.sh}
    '';
  };
in
{
  apps.fetch-hardware-config = {
    type    = "app";
    program = "${fetchHardwareConfig}/bin/fetch-hardware-config";
  };
}
