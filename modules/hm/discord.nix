{ pkgs, ... }:
{
  imports = [
    ../unfree.nix
  ];
  home.packages = with pkgs; [
    discord
  ];
}
