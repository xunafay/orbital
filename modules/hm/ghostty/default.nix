{ pkgs, ... }:
{
  home.file.".config/ghostty/config.ghostty" = {
    source = ./config.ghostty;
    force = true;
  };
  home.file.".config/ghostty/config" = {
    source = ./config.ghostty;
    force = true;
  };
  home.packages = with pkgs; [
    ghostty
  ];
}
