_:
{ lib, inventory, ... }:
let
  relayMachines = lib.filterAttrs (_: m: builtins.elem "relay" (m.tags or [])) inventory.machines;
  dnsServers = relayMachines |> lib.mapAttrsToList (_: m: m.internalIp);
in
{
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = lib.concatStringsSep " " dnsServers;
      Domains = "~${inventory.domain}";
    };
  };

  networking.nameservers = dnsServers;
  networking.networkmanager.dns = "systemd-resolved";
  networking.dhcpcd.extraConfig = "nohook resolv.conf";
}
