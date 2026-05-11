settings:
{ lib, pkgs, inventory, ... }:
{
  services.grafana = {
    declarativePlugins = with pkgs.grafanaPlugins; [
    ];
    provision = {
      datasources.settings.datasources = [

      ];
    };
    enable = true;
    settings = {
      security.secret_key = "SW2YcwTIb9zpOOhoPsMm"; # FIXME: supply secret during runtime?
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        enforce_domain = false;
        enable_gzip = true;
        # analytics.reporting_enabled = false;
      };
    };
  };
  
  orbital.reverseProxy.grafana = {
    domain = "grafana.${inventory.domain}";
    port = 3000;
  };
}
