{ lib, ... }:
{
  options.orbital.postgres = lib.mkOption {
    default = {};
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        user = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "PostgreSQL role/user name.";
        };

        databases = lib.mkOption {
          default = {};
          type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
            options = {
              extensions = lib.mkOption {
                default = _: {};
                type = lib.types.functionTo (lib.types.attrsOf lib.types.package);
              };

              setupSql = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
              };
            };
          }));
          description = "Databases owned/managed for this logical postgres consumer.";
        };
      };
    }));
  };

  options.orbital.secrets.postgres = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        password = lib.mkOption {
          readOnly = true;
          type = lib.types.submodule {
            options = {
              path = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
              };
              secretName = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
              };
              generatorName = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
              };
            };
          };
        };
      };
    });
  };
}
