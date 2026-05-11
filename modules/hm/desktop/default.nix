{ pkgs, ... }:
{
  imports = [
    ./noctalia/default.nix
    ./niri/default.nix
  ];
}
