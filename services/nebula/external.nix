settings:
{ lib, pkgs, inventory, ... }:
let
  relayMachines = lib.filterAttrs (_: m: builtins.elem "relay" (m.tags or [])) inventory.machines;

  lighthouseHostLines = relayMachines
    |> lib.mapAttrsToList (_: m: "- ${m.internalIp}")
    |> lib.concatStringsSep "\n";

  staticHostMapLines = relayMachines
    |> lib.mapAttrsToList (_: m:
        "${m.internalIp}:\n  - ${lib.last (lib.splitString "@" m.deploy.targetHost)}:4242"
      )
    |> lib.concatStringsSep "\n";
in
{
  imports = [ ./secrets.nix ];

  secrets.generators = lib.mkMerge [
    (settings.peers
      |> lib.mapAttrs' (name: peer: {
        name = "nebula-${name}";
        value = {
          files."host.key" = { secret = true; shared = true; };
          files."host.crt" = { secret = true; shared = true; };
          runtimeInputs = [ pkgs.nebula ];
          dependencies = [ "nebula-ca" ];
          script = ''
            nebula-cert sign \
              -name "${name}" \
              -ip "${peer.ip}/24" \
              -ca-crt "$in/nebula-ca/ca.crt" \
              -ca-key "$in/nebula-ca/ca.key" \
              -out-crt "$out/host.crt" \
              -out-key "$out/host.key"
          '';
        };
      }))

    (settings.peers
      |> lib.mapAttrs' (name: peer: {
        name = "nebula-${name}-config";
        value = {
          files."config.yaml" = { secret = true; shared = true; };
          runtimeInputs = [ pkgs.nebula ];
          dependencies = [ "nebula-ca" "nebula-${name}" ];
          script = ''
            indent() { sed 's/^/    /'; }

            CA_CRT=$(indent < "$in/nebula-ca/ca.crt")
            HOST_CRT=$(indent < "$in/nebula-${name}/host.crt")
            HOST_KEY=$(indent < "$in/nebula-${name}/host.key")

            cat > "$out/config.yaml" <<EOF
            cipher: aes
            firewall:
              inbound:
              - ca_name: orbital
                description: any
                port: any
                proto: any
              outbound:
              - description: Allow all outbound
                host: any
                port: any
                proto: any
            lighthouse:
              hosts:
              ${lighthouseHostLines}
              interval: 60
            listen:
              port: 0
            relay:
              relays:
              ${lighthouseHostLines}
              am_relay: false
              use_relays: true
            punchy:
              punch: true
              respond: true
            logging:
              level: info
            mobile_nebula:
              dns_resolvers:
              ${lighthouseHostLines}
              match_domains: []
            pki:
              ca: |
            $CA_CRT
              cert: |
            $HOST_CRT
              key: |
            $HOST_KEY
            static_host_map:
              ${staticHostMapLines}
            static_map:
              network: ip4
            tun:
              mtu: 1300
              unsafe_routes: []
            EOF
          '';
        };
      }))
  ];
}
