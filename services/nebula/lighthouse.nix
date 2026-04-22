settings:
{ inputs, config, machine, pkgs, ... }:
{
  secrets.generators.nebula-ca = {
    files."ca.key" = { secret = true; deploy = false; shared = true; };
    files."ca.crt" = { secret = true; shared = true; };
    runtimeInputs = [ pkgs.nebula ];
    script = ''
      nebula-cert ca -name "orbital" -out-crt "$out/ca.crt" -out-key "$out/ca.key"
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

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 4242 ];
  };

  services.nebula.networks.mesh = {
    enable = true;
    isLighthouse = true;

    ca   = config.sops.secrets."nebula_ca_crt".path;
    cert = config.sops.secrets."nebula_host_crt".path;
    key  = config.sops.secrets."nebula_host_key".path;
  };
}
