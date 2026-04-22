# lib/generate.nix
{ lib, inventory, pkgs, nixosConfigs }:
let
  knownMachines = builtins.attrNames inventory.machines;

  generatorsJson = machineName:
    let
      generators = nixosConfigs.${machineName}.config.secrets.generators;
    in
      builtins.toJSON (lib.mapAttrs (genName: gen: {
        inherit (gen) dependencies script;
        files = lib.mapAttrs (_: f: { inherit (f) secret deploy shared; }) gen.files;
      }) generators);

  generate = pkgs.writeShellApplication {
    name = "generate";
    runtimeInputs = with pkgs; [ jq sops age nebula openssh coreutils git ];
    excludeShellChecks = [ "SC2016" ];
    text = ''
      KNOWN_MACHINES=${lib.escapeShellArg (lib.concatStringsSep " " knownMachines)}

      case "''${1:-}" in
        ${lib.concatMapStringsSep "\n        " (m: ''
          ${m}) GENERATORS_JSON=${lib.escapeShellArg (generatorsJson m)} ;;
        '') knownMachines}
        "")
          echo "Usage: generate <machine>"
          echo "Known machines:"
          for m in $KNOWN_MACHINES; do echo "  - $m"; done
          exit 1 ;;
        *) echo "Unknown machine: ''${1:-}"; exit 1 ;;
      esac

      ${builtins.readFile ./scripts/generate.sh}
    '';
  };
in
{
  apps.generate = {
    type    = "app";
    program = "${generate}/bin/generate";
  };
}
