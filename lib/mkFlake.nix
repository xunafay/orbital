{
  self,
  inputs,
  inventory,
  nixpkgs,
}:
let
  lib  = nixpkgs.lib;
  pkgs = nixpkgs.legacyPackages.x86_64-linux;

  _validated       = import ./inventory.nix  { inherit lib inventory; };
  nixosConfigs     = import ./machines.nix   { inherit lib inputs self inventory pkgs; };
  deployOutputs    = import ./deploy.nix     { inherit lib inventory pkgs nixosConfigs; };
  checkOutputs     = import ./checks.nix     { inherit lib inventory pkgs nixosConfigs; };
  bootstrapOutputs = import ./bootstrap.nix  { inherit lib inputs inventory pkgs; };
  sopsOutputs      = import ./sops.nix       { inherit lib inputs inventory pkgs; };
  installOutputs   = import ./install.nix    { inherit lib inputs inventory pkgs; };
in
{
  nixosConfigurations = nixosConfigs;

  checks.x86_64-linux = checkOutputs;

  apps.x86_64-linux =
    deployOutputs.apps
    // bootstrapOutputs.apps
    // sopsOutputs.apps
    // installOutputs.apps;

  devShells.x86_64-linux.default = pkgs.mkShell {
    packages = with pkgs; [ sops age nebula ssh-to-age yq-go ];
  };
}
