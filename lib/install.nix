{
  lib,
  inputs,
  inventory,
  pkgs,
}:
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
    in "${name}) TARGET=\"${host}\" PORT=\"${builtins.toString port}\" ;;"
  ) knownMachines;

  sshKey = inventory.bootstrapping.allowedSshKey or "";

  installMachine = pkgs.writeShellApplication {
    name = "install-machine";
    runtimeInputs = with pkgs; [ openssh sops age coreutils nix pv rsync ];
    excludeShellChecks = [ "SC2034" ];
    text = ''
      KNOWN_MACHINES=${lib.escapeShellArg (lib.concatStringsSep " " knownMachines)}
      KEXEC_TARBALL=${lib.escapeShellArg kexecTarball}
      BUILD_LOCALLY=0
      SSH_PUBKEY=${lib.escapeShellArg sshKey}
      TARGET=""
      PORT="22"

      POSITIONAL=()
      for arg in "$@"; do
        case "$arg" in
          --local) BUILD_LOCALLY=1 ;;
          --help|-h)
            echo "Usage: install-machine <machine> [--local]"
            echo ""
            echo "  --local   Build system closure locally and push (slow upload)"
            echo "            Default: copy flake source and build on target"
            echo ""
            echo "Known machines:"
            for m in $KNOWN_MACHINES; do echo "  - $m"; done
            exit 0
            ;;
          *) POSITIONAL+=("$arg") ;;
        esac
      done
      set -- "''${POSITIONAL[@]}"

      case "''${1:-}" in
        ${caseArms}
        "")
          echo "Usage: install-machine <machine>"
          echo ""
          echo "Known machines:"
          for m in $KNOWN_MACHINES; do echo "  - $m"; done
          exit 1
          ;;
        *)
          echo "Unknown machine: ''${1:-}"
          echo "Known machines: $KNOWN_MACHINES"
          exit 1
          ;;
      esac
      MACHINE="$1"
      ${builtins.readFile ./scripts/install-machine.sh}
    '';
  };

in
{
  apps = {
    install-machine = {
      type    = "app";
      program = "${installMachine}/bin/install-machine";
    };
  };
}
