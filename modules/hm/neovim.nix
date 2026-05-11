{ lib, pkgs, config, ... }:
with lib;
{
  options = {
  };

  config = {
    home.packages = with pkgs; [
      tree-sitter
      gcc
      ripgrep
      fd
      nodejs_24
      cargo
      rustc
      git
    ];

    home.activation.cloneNvim = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "$HOME/.config/nvim" ]; then
        ${pkgs.git}/bin/git clone https://github.com/xunafay/kickstart.nvim.git $HOME/.config/nvim
      fi
    '';
  };
}
