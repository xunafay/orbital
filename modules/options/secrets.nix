{ lib, config, repoRoot, machine, ... }:
let
  cfg = config.secrets;

  secretPath = genName: fname: fspec:
    if fspec.shared
    then "${repoRoot}/secrets/shared/${genName}/${fname}.yaml"
    else "${repoRoot}/secrets/machines/${machine.name}/${genName}/${fname}.yaml";
in
{
  options.secrets.generators = lib.mkOption {
    default = {};
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        description = lib.mkOption {
          type    = lib.types.str;
          default = "";
        };
        runtimeInputs = lib.mkOption {
          type    = lib.types.listOf lib.types.package;
          default = [];
        };
        script = lib.mkOption {
          type = lib.types.str;
        };
        dependencies = lib.mkOption {
          type    = lib.types.listOf lib.types.str;
          default = [];
        };
        files = lib.mkOption {
          default = {};
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              secret = lib.mkOption {
                type    = lib.types.bool;
                default = true;
              };
              deploy = lib.mkOption {
                type    = lib.types.bool;
                default = true;
              };
              shared = lib.mkOption {
                type    = lib.types.bool;
                default = false;
              };
            };
          });
        };
      };
    });
  };
}
