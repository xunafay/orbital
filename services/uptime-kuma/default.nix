settings:
{ inventory, ... }:
let
  port = 3001;
in
{
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = toString port;
      HOST = "0.0.0.0";
    };
  };

  orbital.reverseProxy.uptime = {
    domain = "uptime.${inventory.domain}";
    port = port;
  };
}
