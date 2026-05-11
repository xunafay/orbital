{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
 
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    awww.url = "git+https://codeberg.org/LGFae/awww";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # bootstrapping
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-images.url = "github:nix-community/nixos-images";
  };
  nixConfig = {
    extra-experimental-features = [ "pipe-operators" "flakes" "nix-command" ];
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      mkFlake = import ./lib/mkFlake.nix;
      inventory = import ./inventory.nix;
    in
    mkFlake {
      inherit self inputs inventory nixpkgs;
    };
}
