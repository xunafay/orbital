_:
{ lib, config, ... }:
{
  config = lib.mkIf (config.orbital.reverseProxy != {}) {
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    services.caddy = {
      enable = true;
      virtualHosts = config.orbital.reverseProxy
        |> lib.mapAttrs' (_: svc: {
            name = "http://${svc.domain}";
            value.extraConfig = "reverse_proxy localhost:${toString svc.port}";
          });
    };
  };
}
