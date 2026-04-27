_:
{ lib, config, machine, inventory, ... }:
let
  relayMachines = lib.filterAttrs (_: m: builtins.elem "relay" (m.tags or [])) inventory.machines;
  relayIps = relayMachines |> lib.mapAttrsToList (_: m: m.internalIp);

  machineEntries = inventory.machines
    |> lib.mapAttrsToList (name: m: "${m.internalIp}  ${name}.${inventory.domain}")
    |> lib.concatStringsSep "\n        ";

  serviceEntries = config.orbital.reverseProxy
    |> lib.mapAttrsToList (_: svc: "${machine.internalIp}  ${svc.domain}")
    |> lib.concatStringsSep "\n        ";
in
{
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  services.coredns = {
    enable = true;
    config = ''
      ${inventory.domain} {
        bind ${lib.concatStringsSep " " relayIps}
        hosts {
          ${machineEntries}
          ${serviceEntries}
          fallthrough
        }
        cache 30
        log
        errors
      }
    '';
  };
}
