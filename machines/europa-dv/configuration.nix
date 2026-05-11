{ pkgs, ... }:
{
  imports = [
    ./disko.nix
    ../../modules/software/greeter.nix
  ];

  networking.hostName = "europa-dv";
  time.timeZone = "Europe/Brussels";
  system.stateVersion = "25.05";
}
