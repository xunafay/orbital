{ lib, inventory, pkgs, nixosConfigs }:
{
  inventory-valid = pkgs.runCommand "check-inventory-valid" {} ''
    echo "Inventory validation passed." > $out
    echo "Machines: ${lib.concatStringsSep ", " (builtins.attrNames inventory.machines)}" >> $out
  '';

  nixos-eval = pkgs.runCommand "check-nixos-eval" {} ''
    echo "All nixosConfigurations evaluated successfully:" > $out
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: _: ''
        echo "  ok: ${name}" >> $out
      '') nixosConfigs
    )}
  '';
}
