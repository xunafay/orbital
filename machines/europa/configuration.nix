{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/software/greeter.nix
  ];

  networking.hostName = "europa";
  time.timeZone = "Europe/Brussels";
  system.stateVersion = "25.05";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "65536"; }
  ];
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 14d";
  };
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
     # Add any missing dynamic libraries for unpackaged programs
     # here, NOT in environment.systemPackages
  ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
  programs.dconf.enable = true;
  services.upower.enable = true;
}
