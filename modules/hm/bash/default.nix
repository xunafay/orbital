
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bash
  ];

  programs.bash = {
    enable = true;
    bashrcExtra = builtins.readFile ./bashrc.sh;
  };
}
