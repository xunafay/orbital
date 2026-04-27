settings:
{ lib, pkgs, ... }:
{
  imports = [ ./external.nix ];

  services.resolved.domains = [ "~orbital.lan" ];
  networking.nameservers = [ "10.10.0.1" ];
}
