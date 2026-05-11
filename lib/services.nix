{ lib, inventory }:
name: machine:
let
  machineTags = machine.tags or [];

  roleApplies = roleConfig:
    let
      tags = roleConfig.tags or [];
      machineConfigs = roleConfig.machines or {};
    in
      builtins.any (tag:
        tag == "all" || builtins.elem tag machineTags
      ) tags
      || builtins.hasAttr name machineConfigs;

  roleSettings = roleConfig:
    let
      machineConfigs = roleConfig.machines or {};
      machineSettings =
        if builtins.hasAttr name machineConfigs
        then machineConfigs.${name}
        else {};
    in
      lib.recursiveUpdate
        (roleConfig.settings or {})
        machineSettings;

  loadModule = serviceName: roleName:
    let
      roleFile = ../services/${serviceName}/${roleName}.nix;
      defaultFile = ../services/${serviceName}/default.nix;
    in
      import (
        if builtins.pathExists roleFile
        then roleFile
        else defaultFile
      );
in
(inventory.services or {})
|> lib.mapAttrsToList (serviceName: serviceConfig:
  (serviceConfig.roles or {})
  |> lib.mapAttrsToList (roleName: roleConfig:
    lib.optionals (roleApplies roleConfig) [
      ((loadModule serviceName roleName) (roleSettings roleConfig))
    ]
  )
  |> lib.concatLists
)
|> lib.concatLists
