{ pkgs, ... }:
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
}
