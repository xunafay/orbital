settings:
{ inventory, pkgs, config, lib, ... }:
let
  port = settings.port or 5432;
  replicationUser = settings.replicationUser or "postgres_replicator";
  primaryHost = settings.primaryHost or "postgres.${inventory.domain}";
  dataDir = config.services.postgresql.dataDir;
in
{
  networking.firewall.allowedTCPPorts = [ port ];

  services.postgresql = {
    package = pkgs.postgresql_18;
    enable = true;
    enableTCPIP = true;

    settings = {
      port = port;
      listen_addresses = "*";
      hot_standby = true;
    };

    authentication = ''
      # type  database  user  address      auth-method
      host    all       all   10.0.0.0/8   scram-sha-256
    '';
  };

  sops.secrets."postgresql_replication_password" = {
    sopsFile = ../../secrets/shared/postgresql-replication-password/replication.password.yaml;
    format = "yaml";
    key = "data";
    owner = "postgres";
  };

    systemd.tmpfiles.rules = [
      "d /var/lib/postgresql/18 0755 postgres postgres -"
  ];

  systemd.services."postgresql-replica-bootstrap" = {
    enable = true;
    description = "Bootstrap PostgreSQL replica from primary";
    wantedBy = [ "multi-user.target" ];
    before = [ "postgresql.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ postgresql_18 coreutils ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      RemainAfterExit = true;
    };
    script = ''
      set -o errexit -o pipefail -o nounset -o errtrace
      shopt -s inherit_errexit

      if [ -e "${dataDir}/PG_VERSION" ]; then
        echo "PostgreSQL data directory already initialized, skipping replica bootstrap"
        exit 0
      fi

      rm -rf "${dataDir}"
      mkdir -p "${dataDir}"
      chmod 700 "${dataDir}"

      export PGPASSWORD="$(cat ${config.sops.secrets."postgresql_replication_password".path})"

      pg_basebackup \
        -h "${primaryHost}" \
        -p "${toString port}" \
        -U "${replicationUser}" \
        -D "${dataDir}" \
        -Fp \
        -Xs \
        -R

      chmod 700 "${dataDir}"
    '';
  };
}
