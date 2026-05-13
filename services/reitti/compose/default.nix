{ pkgs, lib, config, inventory, ... }:

{
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  # Enable container name DNS for all Podman networks.
  networking.firewall.interfaces = let
    matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
  in {
    "${matchAll}".allowedUDPPorts = [ 53 ];
  };

  virtualisation.oci-containers.backend = "podman";

  # Containers
  virtualisation.oci-containers.containers."reitti-redis" = {
    image = "redis:7-alpine";
    volumes = [
      "reitti_redis-data:/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=[\"redis-cli\", \"ping\"]"
      "--health-interval=10s"
      "--health-retries=5"
      "--health-timeout=5s"
      "--network-alias=redis"
      "--network=reitti_default"
    ];
  };
  systemd.services."podman-reitti-redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-reitti_default.service"
      "podman-volume-reitti_redis-data.service"
    ];
    requires = [
      "podman-network-reitti_default.service"
      "podman-volume-reitti_redis-data.service"
    ];
    partOf = [
      "podman-compose-reitti-root.target"
    ];
    wantedBy = [
      "podman-compose-reitti-root.target"
    ];
  };

  orbital.postgres.reitti = {
    user = "reitti";
    databases.reitti = {
      extensions = ps: {
        postgis = ps.postgis;
      };
    };
  };

  virtualisation.oci-containers.containers."reitti-reitti" = {
    image = "dedicatedcode/reitti:latest";
    environment = {
      "POSTGIS_DB" = "reitti";
      "POSTGIS_HOST" = "postgres.${inventory.domain}";
      "POSTGIS_USER" = "reitti";
    };
    environmentFiles = [
      "/run/reitti/reitti.env"
    ];
    volumes = [
      "reitti_reitti-data:/data:rw"
    ];
    ports = [
      "3003:8080/tcp"
    ];
    dependsOn = [
      "reitti-postgis"
      "reitti-redis"
      "reitti-tile-cache"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=reitti"
      "--network=reitti_default"
    ];
  };
  systemd.services."podman-reitti-reitti" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "postgresql-password-setup.service"
      "reitti-env.service"
      "podman-network-reitti_default.service"
      "podman-volume-reitti_reitti-data.service"
    ];
    requires = [
      "postgresql-password-setup.service"
      "reitti-env.service"
      "podman-network-reitti_default.service"
      "podman-volume-reitti_reitti-data.service"
    ];
    partOf = [
      "podman-compose-reitti-root.target"
    ];
    wantedBy = [
      "podman-compose-reitti-root.target"
    ];
  };

  systemd.services."reitti-env" = {
    description = "Generate runtime environment for reitti";
    before = [ "podman-reitti-reitti.service" ];
    wantedBy = [ "podman-reitti-reitti.service" ];
    serviceConfig = {
      Type = "oneshot";
      RuntimeDirectory = "reitti";
      RuntimeDirectoryMode = "0700";
      RemainAfterExit = true;
    };
    script = ''
      cat > /run/reitti/reitti.env <<EOF
      POSTGIS_PASSWORD=$(cat ${config.orbital.secrets.postgres.reitti.password.path})
      EOF
      chmod 600 /run/reitti/reitti.env
    '';
  };

  virtualisation.oci-containers.containers."reitti-tile-cache" = {
    image = "dedicatedcode/reitti-tile-cache:latest";
    volumes = [
      "reitti_tile-cache-data:/var/cache/nginx:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=[\"wget\", \"--quiet\", \"--tries=1\", \"--spider\", \"http://127.0.0.1/osm/0/0/0.png\"]"
      "--health-interval=10s"
      "--health-retries=5"
      "--health-timeout=5s"
      "--network-alias=tile-cache"
      "--network=reitti_default"
    ];
  };
  systemd.services."podman-reitti-tile-cache" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-reitti_default.service"
      "podman-volume-reitti_tile-cache-data.service"
    ];
    requires = [
      "podman-network-reitti_default.service"
      "podman-volume-reitti_tile-cache-data.service"
    ];
    partOf = [
      "podman-compose-reitti-root.target"
    ];
    wantedBy = [
      "podman-compose-reitti-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-reitti_default" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f reitti_default";
    };
    script = ''
      podman network inspect reitti_default || podman network create reitti_default
    '';
    partOf = [ "podman-compose-reitti-root.target" ];
    wantedBy = [ "podman-compose-reitti-root.target" ];
  };

  # Volumes
  systemd.services."podman-volume-reitti_postgis-data" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect reitti_postgis-data || podman volume create reitti_postgis-data
    '';
    partOf = [ "podman-compose-reitti-root.target" ];
    wantedBy = [ "podman-compose-reitti-root.target" ];
  };
  systemd.services."podman-volume-reitti_redis-data" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect reitti_redis-data || podman volume create reitti_redis-data
    '';
    partOf = [ "podman-compose-reitti-root.target" ];
    wantedBy = [ "podman-compose-reitti-root.target" ];
  };
  systemd.services."podman-volume-reitti_reitti-data" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect reitti_reitti-data || podman volume create reitti_reitti-data
    '';
    partOf = [ "podman-compose-reitti-root.target" ];
    wantedBy = [ "podman-compose-reitti-root.target" ];
  };
  systemd.services."podman-volume-reitti_tile-cache-data" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect reitti_tile-cache-data || podman volume create reitti_tile-cache-data
    '';
    partOf = [ "podman-compose-reitti-root.target" ];
    wantedBy = [ "podman-compose-reitti-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-reitti-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
