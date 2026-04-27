settings:
{ inputs, config, machine, pkgs, ... }:
{
  imports = [ ./secrets.nix ];

  secrets.generators."nebula-${machine.name}" = {
    files."host.key" = { secret = true; };
    files."host.crt" = { secret = true; };
    runtimeInputs = [ pkgs.nebula ];
    dependencies = [ "nebula-ca" ];
    script = ''
      nebula-cert sign \
        -name "${machine.name}" \
        -ip "${machine.internalIp}/24" \
        -ca-crt "$in/nebula-ca/ca.crt" \
        -ca-key "$in/nebula-ca/ca.key" \
        -out-crt "$out/host.crt" \
        -out-key "$out/host.key"
    '';
  };

  sops.secrets."nebula_ca_crt" = {
    sopsFile = ../../secrets/shared/nebula-ca/ca.crt.yaml;
    format = "yaml";
    key = "data";
    owner = "nebula-mesh";
  };
  sops.secrets."nebula_host_crt" = {
    sopsFile = ../../secrets/machines/${machine.name}/nebula-${machine.name}/host.crt.yaml;
    format = "yaml";
    key = "data";
    owner = "nebula-mesh";
  };
  sops.secrets."nebula_host_key" = {
    sopsFile = ../../secrets/machines/${machine.name}/nebula-${machine.name}/host.key.yaml;
    format = "yaml";
    key = "data";
    owner = "nebula-mesh";
  };

  networking.hosts = {
    "${machine.internalIp}" = [ "${machine.name}.mesh" ];
  };

  networking.firewall.trustedInterfaces = [ "nebula.mesh" ];

  services.nebula.networks.mesh = {
    enable = true;
    isLighthouse = false;
    staticHostMap = {
      "${settings.lighthouseIp}" = [ "${settings.lighthouseHost}:4242" ];
    };
    relays = [ "${settings.lighthouseIp}" ];
    settings = {
      punchy = {
        punch = true;
        respond = true;
      };
    };
    lighthouses = [ settings.lighthouseIp ];
    ca   = config.sops.secrets."nebula_ca_crt".path;
    cert = config.sops.secrets."nebula_host_crt".path;
    key  = config.sops.secrets."nebula_host_key".path;
    firewall.inbound = [
      {
        host = "any";
        port = "any";
        proto = "any";
      }
    ];
    firewall.outbound = [
      {
        host = "any";
        port = "any";
        proto = "any";
      }
    ];
  };
}
