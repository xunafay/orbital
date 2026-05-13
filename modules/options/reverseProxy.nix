{ lib, ... }:
{
  options.orbital.reverseProxy = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        port = lib.mkOption { type = lib.types.port; };
        domain = lib.mkOption { type = lib.types.str; };
        tls = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
    });
    default = {};
  };
}
