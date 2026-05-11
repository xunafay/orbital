{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      fira-code
      jetbrains-mono
      twitter-color-emoji
      material-symbols
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Roboto Nerd Font" ];
        serif = [ "Roboto Nerd Font" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };
}
