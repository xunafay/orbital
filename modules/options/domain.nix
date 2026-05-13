
{ lib, ... }:
{
  options.orbital.domain = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        domain = lib.mkOption { type = lib.types.str; };
      };
    });
    default = {};
  };
}
