_:
{ lib, config, machine, inventory, ... }:
let
  relayMachines = lib.filterAttrs (_: m: builtins.elem "relay" (m.tags or [])) inventory.machines;
  relayIps = relayMachines |> lib.mapAttrsToList (_: m: m.internalIp);

  machineEntries = inventory.machines
    |> lib.mapAttrsToList (name: m: "${m.internalIp}  ${name}.orbital.lan")
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
      orbital.lan {
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

      . {
        bind ${lib.concatStringsSep " " relayIps}
        forward . 1.1.1.1 1.0.0.1
        cache 30
        errors
      }
    '';
  };
}
