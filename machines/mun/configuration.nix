{ pkgs, ... }:
{
  imports = [
    ./disko.nix
    ../../modules/reitti/default.nix
  ];

  networking.hostName = "mun";
  time.timeZone = "Europe/Brussels";
  system.stateVersion = "25.05";
}
