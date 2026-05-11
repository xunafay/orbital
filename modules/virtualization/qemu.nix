{ lib, pkgs, ... }:
with lib;
{
  options = {
  };

  config = {
    environment.systemPackages = with pkgs; [
      qemu
      quickemu
    ];

    # enable UEFI firmware support
    systemd.tmpfiles.rules = [ "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware" ];

    boot.binfmt.emulatedSystems = [
      "aarch64-linux"
      "riscv64-linux"
    ];
  };
}
