{ pkgs, ... }:
{
  imports = [
    ../unfree.nix
  ];
  home.packages = with pkgs; [
    teams-for-linux
  ];
}
