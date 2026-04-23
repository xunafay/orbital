{
  boot = {
    loader = {
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
    };
  };
  disko.devices = {
    disk = {
      main = {
        name = "main-20139fdd4ecb46be9d673d9f696f88cd";
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            "boot" = {
              size = "1M";
              type = "EF02"; # for grub MBR
              priority = 1;
            };
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
