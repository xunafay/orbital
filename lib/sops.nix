# nix run .#init-sops-machine -- <machine>
#
# generates (if not already present):
#   - an age keypair for the machine
#   - an ed25519 SSH host keypair for the machine
# stores pubkeys as plaintext in secrets/pubkeys/machines/
# encrypts private keys (admin-only) into secrets/machines/<machine>/
# adds age keys to .sops.yaml with per-machine creation rules
#
# nix run .#secret -- edit secrets/machines/<machine>/foo.yaml
#
# basically wraps sops with SOPS_AGE_KEY_FILE set correctly and some helper funcs
{
  lib,
  inputs,
  inventory,
  pkgs,
}:
let
  knownMachines = builtins.attrNames inventory.machines;

  initSopsMachine = pkgs.writeShellApplication {
    name = "init-sops-machine";
    runtimeInputs = with pkgs; [ age openssh sops yq-go coreutils gnugrep ];
    text = ''
      KNOWN_MACHINES=${lib.escapeShellArg (lib.concatStringsSep " " knownMachines)}
      ${builtins.readFile ./scripts/init-sops-machine.sh}
    '';
  };

  secret = pkgs.writeShellApplication {
    name = "secret";
    runtimeInputs = with pkgs; [ sops coreutils ];
    text = builtins.readFile ./scripts/secret.sh;
  };

in
{
  apps = {
    init-sops-machine = {
      type    = "app";
      program = "${initSopsMachine}/bin/init-sops-machine";
    };
    secret = {
      type    = "app";
      program = "${secret}/bin/secret";
    };
  };
}
