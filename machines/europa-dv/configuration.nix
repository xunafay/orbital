{
  imports = [
    ./disko.nix
  ];
  
  networking.hostName = "europa-dv";
  time.timeZone = "Europe/Brussels";
  system.stateVersion = "25.05";
}
