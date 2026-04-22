{
  imports = [
    ./disko.nix
  ];

  networking.hostName = "mun";
  time.timeZone = "Europe/Brussels";
  system.stateVersion = "25.05";
}
