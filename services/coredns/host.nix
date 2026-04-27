settings:
{ lib, pkgs, ... }:
{
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  services.coredns = {
    enable = true;
    config = ''
      orbital.lan {
        hosts {
          10.10.0.1   mun.orbital.lan
          10.10.0.2   europa-dv.orbital.lan
          fallthrough
        }
        cache 30
      }
    '';
  };
}

