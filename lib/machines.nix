{ lib, inputs, self, inventory, pkgs }:
let
  serviceModulesForMachine = import ./services.nix { inherit lib inventory; };
in
lib.mapAttrs (name: machine:
  lib.nixosSystem {
    system = machine.system or "x86_64-linux";
    specialArgs = {
      inherit inputs self inventory;
      machine = { name = name; internalIp = machine.internalIp; };
    };
    modules =
      [
        ../modules/secrets.nix
        ../machines/${name}/configuration.nix
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
      ]
      ++ lib.optionals (builtins.pathExists ../machines/${name}/facter.json) [
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ../machines/${name}/facter.json; }
      ]
      ++ lib.optionals (!builtins.pathExists ../machines/${name}/facter.json) [
        { warnings = [ "machine '${name}' has no facter.json — run nixos-facter on the target" ]; }
      ]
      ++ serviceModulesForMachine name machine;
  }
) inventory.machines
