{ lib, inventory }:
name: machine:
lib.concatLists (
  lib.mapAttrsToList (serviceName: serviceConfig:
    lib.concatLists (
      lib.mapAttrsToList (roleName: roleConfig:
        let
          tags    = roleConfig.tags or [];
          matches = builtins.any (tag:
            tag == "all" || builtins.elem tag (machine.tags or [])
          ) tags;
          settings = roleConfig.settings or {};
          roleFile    = ../services/${serviceName}/${roleName}.nix;
          defaultFile = ../services/${serviceName}/default.nix;
          moduleFile  = if builtins.pathExists roleFile then roleFile else defaultFile;
          module      = import moduleFile;
        in
        lib.optionals matches [ (module settings) ]
      ) (serviceConfig.roles or {})
    )
  ) (inventory.services or {})
)
