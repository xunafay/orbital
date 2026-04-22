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
        name = "main-55d899cf4bf048dda13b248aaa91eb64";
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_116542589";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            "boot" = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
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
