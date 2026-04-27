{
  domain = "orbital.lan";

  machines = {
    mun = {
      tags = [ "relay" "server" "dns" ];
      deploy.targetHost = "root@204.168.191.193";
      # deploy.buildHost = "root@";
      internalIp = "10.10.0.1";
    };
    europa-dv = {
      tags = [ "tethered" "workstation" ];
      deploy.targetHost = "root@localhost";
      deploy.targetPort = 22220;
      internalIp = "10.10.0.2";
    };
  };

  bootstrapping = {
    allowedSshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCp/tF+KkZT8BALDgc/+/dnxa8K6SMFPp8QIHXn69ZNe7IlK1rtT1VYdqaeyfjPSuHypP7Yzm/c8BCW1bDwZw267FhF8VpqWewFr2F3gD+4ErHYSlRvp8pNNpqMhEagBCookpDf14bkTIFl4KVOEJbRaEP58EjAEvcQNBF3D2WBvJ7OkE4cosf7h5YUT4dvCuNbpfwE+pdqenLwBUQTKlfUwgSXkZBavVbkKLJnocuN6iBfCngEZpcv3lk2hSY+Z1hIGd8Pv9gA1+SIR8lLfXgmssprt+MRzHI+duN7b6t8ayb/f/JudSb9cXTmQk0H2TLK3NW44p0qV9k9wqkUCChbXv0RuUtzyc5k97t5D9NtN6baeSJqeiEIuRKZIr9eqYjGMaXYRc/JRdq84ui68iaYnW2x58hr/OPxw4ittMR2nSlXO+ea7kYkUvomVsIrmmDwVKoQkbE9yLsaDAZqT+vzEdBRgIr/q8wLEyM9EE2LEtEFn/Nn/rOj0fju8iEvhW+4FmW0ocoyKvOX1c7FUgpf2qUk0fYg5y047y6WoAXBIoPI6itVU6A7EXTg8zjHisyqqVuwTfh4DNcFVbdXvR4jWwTj6xgAZYEZwWj1vkTm8PVt3wTa5HH2eVbuqDfzgb4AxZuNin5hAPro+0IOr2SiaI/QuPVZ7H+78AQADo8tQw==";
  };

  # resolves which service modules a machine should receive
  # based on role -> tag matching against the inventory.
  #
  # service directory convention:
  #   services/<service-name>/<role-name>.nix
  # if a role is not found, it will fall back to services/<service-name>/default.nix.
  #
  # inventory convention:
  #   services.<service-name>.roles.<role-name> = {
  #     tags     = [ "tag1" "tag2" ];  # "all" matches every machine
  #     settings = { ... };            # passed as first arg to the module
  services = {
    sops = {
      roles.default.tags = [ "all" ];
    };
    coredns = {
      roles.host.tags = [ "dns" ];
      roles.default.tags = [ "all" ];
    };
    caddy = {
        roles.default.tags = [ "server" ];
    };
    modules = {
      roles.workstation.tags = [ "workstation" ];
      roles.workstation.settings = {
        modules = [
          ./modules/networkmanager.nix
        ];
      };
    };
    hello = {
      roles.default.tags = [ "server" ];
    };
    firewall = {
      roles.default.tags = [ "all" ];
      roles.spotify.tags = [ "workstation" ];
    };
    nebula = {
      roles.lighthouse.tags = [ "relay" ];
      roles.peer.tags = [ "tethered" ]; 
      roles.external.tags = [ "all" ];
      roles.external.settings = {
        peers = {
          "hannah-phone" = {
            ip = "10.10.0.200";
          };
        };
      };
    };
    admin-ssh = {
      roles.default.tags = [ "all" ];
      roles.default.settings = {
        keys = {
          root = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCp/tF+KkZT8BALDgc/+/dnxa8K6SMFPp8QIHXn69ZNe7IlK1rtT1VYdqaeyfjPSuHypP7Yzm/c8BCW1bDwZw267FhF8VpqWewFr2F3gD+4ErHYSlRvp8pNNpqMhEagBCookpDf14bkTIFl4KVOEJbRaEP58EjAEvcQNBF3D2WBvJ7OkE4cosf7h5YUT4dvCuNbpfwE+pdqenLwBUQTKlfUwgSXkZBavVbkKLJnocuN6iBfCngEZpcv3lk2hSY+Z1hIGd8Pv9gA1+SIR8lLfXgmssprt+MRzHI+duN7b6t8ayb/f/JudSb9cXTmQk0H2TLK3NW44p0qV9k9wqkUCChbXv0RuUtzyc5k97t5D9NtN6baeSJqeiEIuRKZIr9eqYjGMaXYRc/JRdq84ui68iaYnW2x58hr/OPxw4ittMR2nSlXO+ea7kYkUvomVsIrmmDwVKoQkbE9yLsaDAZqT+vzEdBRgIr/q8wLEyM9EE2LEtEFn/Nn/rOj0fju8iEvhW+4FmW0ocoyKvOX1c7FUgpf2qUk0fYg5y047y6WoAXBIoPI6itVU6A7EXTg8zjHisyqqVuwTfh4DNcFVbdXvR4jWwTj6xgAZYEZwWj1vkTm8PVt3wTa5HH2eVbuqDfzgb4AxZuNin5hAPro+0IOr2SiaI/QuPVZ7H+78AQADo8tQw==";
        };
      };
    };
  };
}
