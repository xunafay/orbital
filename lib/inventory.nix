{ lib, inventory }:
let
  fieldErrors = lib.concatLists (
    lib.mapAttrsToList (name: machine:
      lib.optionals (!machine ? nebulaIp) [
        "machine '${name}' is missing required field: nebulaIp"
      ]
      ++ lib.optionals (!machine ? tags) [
        "machine '${name}' is missing required field: tags"
      ]
      ++ lib.optionals (machine ? nebulaIp && !builtins.isString machine.nebulaIp) [
        "machine '${name}' nebulaIp must be a string"
      ]
    ) inventory.machines
  );

  allIps    = lib.mapAttrsToList (_: m: m.nebulaIp or "") inventory.machines;
  uniqueIps = lib.unique allIps;
  ipErrors  = lib.optionals (lib.length allIps != lib.length uniqueIps) [
    "duplicate nebulaIp values detected"
  ];

  allErrors = fieldErrors ++ ipErrors;
in
  assert (
    allErrors == [] || abort (
      "Inventory validation failed:\n" +
      lib.concatMapStringsSep "\n" (e: "  - ${e}") allErrors
    )
  );
  { machines = builtins.attrNames inventory.machines; }
