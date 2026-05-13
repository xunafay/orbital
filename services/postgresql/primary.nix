settings:
{ inventory, pkgs, config, lib, ... }:
let
  port = settings.port or 5432;
  replicationUser = settings.replicationUser or "postgres_replicator";

  secretNameFor = name: "postgresql_${name}_password";
  generatorNameFor = name: "postgresql-${name}-password";
  secretFileFor = name: ../../secrets/shared + "/postgresql-${name}-password/${name}.password.yaml";

  serviceNames = lib.attrNames config.orbital.postgres;

  allDatabases =
    config.orbital.postgres
    |> lib.mapAttrsToList (_: svc: lib.attrNames svc.databases)
    |> lib.flatten
    |> lib.unique;

  ensureUsers =
    config.orbital.postgres
    |> lib.mapAttrsToList (_: svc: {
      name = svc.user;
      ensureDBOwnership = false;
      ensureClauses = {
        login = true;
      };
    });

  extensionPackages = ps:
    config.orbital.postgres
    |> lib.mapAttrsToList (_: svc:
      svc.databases
      |> lib.mapAttrsToList (_: db:
        lib.attrValues (db.extensions ps)
      )
    )
    |> lib.flatten
    |> lib.flatten
    |> lib.unique;

  passwordGenerators =
    config.orbital.postgres
    |> lib.mapAttrs' (name: _: {
      name = generatorNameFor name;
      value = {
        files."${name}.password" = {
          secret = true;
          shared = true;
        };
        script = ''
          read -s -p "Enter password for PostgreSQL user '${name}': " password
          echo "$password" > "$out/${name}.password"
        '';
      };
    });

  passwordSecrets =
    config.orbital.postgres
    |> lib.mapAttrs' (name: _: {
      name = secretNameFor name;
      value = {
        sopsFile = secretFileFor name;
        format = "yaml";
        key = "data";
        owner = "postgres";
      };
    });

  secretExports =
    config.orbital.postgres
    |> lib.mapAttrs (name: _: {
      password = {
        path = config.sops.secrets."${secretNameFor name}".path;
        secretName = secretNameFor name;
        generatorName = generatorNameFor name;
      };
    });

  serviceSetupScript =
    config.orbital.postgres
    |> lib.mapAttrsToList (svcName: svc:
      let
        secretPath = config.sops.secrets.${secretNameFor svcName}.path;

        perDatabaseScript =
          svc.databases
          |> lib.mapAttrsToList (dbName: db:
            let
              extNames = lib.attrNames (db.extensions pkgs.postgresql_18.pkgs);

              extensionScript =
                extNames
                |> map (extName:
                  ''
                    retry 5 psql "${dbName}" -c 'CREATE EXTENSION IF NOT EXISTS "${extName}";'
                  '')
                |> lib.concatStringsSep "\n";

              setupSqlScript =
                if db.setupSql == null then
                  ""
                else
                  ''
                    tmp_file=$(mktemp)
                    install --mode 600 ${db.setupSql} "$tmp_file"
                    ${pkgs.replace-secret}/bin/replace-secret @DB_PASSWORD@ ${secretPath} "$tmp_file"
                    retry 5 psql "${dbName}" --file "$tmp_file"
                    rm -f "$tmp_file"
                  '';
            in
              ''
                ${extensionScript}
                ${setupSqlScript}
              '')
          |> lib.concatStringsSep "\n";
      in
        ''
          retry 5 psql postgres -c "ALTER ROLE \"${svc.user}\" WITH PASSWORD '$(cat ${secretPath})';"
          ${perDatabaseScript}
        '')
    |> lib.concatStringsSep "\n";

  databaseAuthLines =
    config.orbital.postgres
    |> lib.mapAttrsToList (_: svc:
      map (dbName:
        "host    ${dbName}    ${svc.user}    10.0.0.0/8    scram-sha-256"
      ) (lib.attrNames svc.databases)
    )
    |> lib.flatten
    |> lib.concatStringsSep "\n";
in
{
  networking.firewall.allowedTCPPorts = [ port ];

  services.postgresql = {
    package = pkgs.postgresql_18;
    enable = true;
    enableTCPIP = true;
    port = port;

    ensureDatabases = allDatabases;

    settings = {
      listen_addresses = "*";
      wal_level = "replica";
      max_wal_senders = 10;
      max_replication_slots = 10;
      hot_standby = true;
      synchronous_commit = "local";
    };

    authentication = ''
      # type  database     user                address        auth-method
      local   replication  ${replicationUser}                 peer
      host    replication  ${replicationUser}  10.0.0.0/8     scram-sha-256

      ${databaseAuthLines}
    '';

    extensions = extensionPackages;

    ensureUsers = ensureUsers ++ [
      {
        name = replicationUser;
        ensureDBOwnership = false;
        ensureClauses = {
          login = true;
          replication = true;
        };
      }
    ];
  };

  systemd.services."postgresql-password-setup" = {
    enable = true;
    description = "Set up PostgreSQL users, passwords, extensions, and extra SQL";
    after = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    requires = [ "postgresql.service" ];
    path = with pkgs; [ postgresql_18 replace-secret ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      RuntimeDirectory = "postgresql-setup";
      RuntimeDirectoryMode = "700";
    };
    script = ''
      set -o errexit -o pipefail -o nounset -o errtrace
      shopt -s inherit_errexit

      retry() {
        local attempts="$1"
        shift
        local n=1
        while true; do
          if "$@"; then
            return 0
          fi
          if [ "$n" -ge "$attempts" ]; then
            echo "command failed after $attempts attempts: $*" >&2
            return 1
          fi
          echo "command failed, retrying ($n/$attempts): $*" >&2
          n=$((n + 1))
          sleep 1
        done
      }

      ${serviceSetupScript}

      retry 5 psql postgres -c "ALTER ROLE \"${replicationUser}\" WITH PASSWORD '$(cat ${config.sops.secrets."postgresql_replication_password".path})';"
    '';
  };

  system.activationScripts.postgresqlSetup = ''
    ${pkgs.systemd}/bin/systemctl restart postgresql-password-setup.service
  '';

  secrets.generators =
    passwordGenerators
    // {
      "postgresql-replication-password" = {
        files."replication.password" = {
          secret = true;
          shared = true;
        };
        script = ''
          read -s -p "Enter password for PostgreSQL replication user '${replicationUser}': " password
          echo "$password" > "$out/replication.password"
        '';
      };
    };

  sops.secrets =
    passwordSecrets
    // {
      "postgresql_replication_password" = {
        sopsFile = ../../secrets/shared/postgresql-replication-password/replication.password.yaml;
        format = "yaml";
        key = "data";
        owner = "postgres";
      };
    };

  orbital.secrets.postgres = secretExports;

  orbital.domain.postgres = {
    domain = "postgres.${inventory.domain}";
  };
}
