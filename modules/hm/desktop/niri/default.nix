{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.niri.homeModules.niri  # Import Niri's home-manager module
    ./settings.nix                # Your custom configuration files for Niri
    ./keybinds.nix
    ./rules.nix
    ./autostart.nix
    ./scripts.nix
  ];
  home.packages = with pkgs; [
    quickshell
    wallust
    bc
  ];
}
