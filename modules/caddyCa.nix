{ config, pkgs, ... }:
{
  secrets.generators."caddy-ca" = {
    files."ca.crt" = { secret = false; shared = true; };
    files."ca.key" = { secret = true; shared = true; };
    runtimeInputs = [ pkgs.step-cli ];
    script = ''
      ${pkgs.step-cli}/bin/step certificate create \
        "Orbital Internal CA" \
        "$out/ca.crt" "$out/ca.key.ec" \
        --profile root-ca \
        --no-password \
        --insecure \
        --kty EC
      ${pkgs.openssl}/bin/openssl pkcs8 -topk8 -nocrypt -in $out/ca.key.ec -out $out/ca.key
    '';
  };

  environment.etc."caddy-ca/ca.crt".source = ../secrets/shared/caddy-ca/ca.crt;
  sops.secrets."caddy_ca_key" = {
    sopsFile = ../secrets/shared/caddy-ca/ca.key.yaml;
    format = "yaml";
    key = "data";
    owner = "caddy";
    group = "caddy";
    mode = "0400";
  };
  services.caddy.globalConfig = ''
    pki {
      ca local {
        name "Orbital Internal CA"
        root {
          format pem_file
          cert /etc/caddy-ca/ca.crt
          key  ${config.sops.secrets."caddy_ca_key".path}
        }
      }
    }
  '';
  security.pki.certificateFiles = [ ../secrets/shared/caddy-ca/ca.crt ];
}
