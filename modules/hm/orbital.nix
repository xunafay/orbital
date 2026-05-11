{ lib, pkgs, config, ... }:
with lib;
{
  imports = [
    ../software/direnv.nix
  ];

  options = {
  };

  config = {

    home.packages = with pkgs; [
      git
    ];

    home.activation.cloneOrbital = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "$HOME/orbital" ]; then
        ${pkgs.git}/bin/git clone https://tangled.org/xunafay.tngl.sh/orbital $HOME/orbital
      fi
    '';
  };
}
