_:
{ lib, config, pkgs, ... }:
{
  imports = [
    ../../modules/caddyCa.nix
  ];
  config = lib.mkIf (config.orbital.reverseProxy != {}) {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.caddy = {
      enable = true;
      virtualHosts = config.orbital.reverseProxy
        |> lib.mapAttrs' (_: svc: {
            name = svc.domain;
            value.extraConfig = ''
              reverse_proxy localhost:${toString svc.port}
              tls internal
            '';
          });
    };
  };
}
