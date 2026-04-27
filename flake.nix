{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
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
