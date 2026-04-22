# Orbital - a NixOS config for my homelab

Inspired by [clan.lol](https://clan.lol)

### Secret Management

Secrets are stored under `secrets/` and are encrypted using `sops`. To manage secrets see `lib/sops.nix`.

### Machine Configurations

Each machine has its own directory under `machines/`. The entry point is `configuration.nix`.

#### Bootstrapping

Make sure the machine is defined in `inventory.nix` and has a `deploy.targetHost` set and is reachable via ssh.

```bash
# create a facter.json for the machine.
nix run .#fetch-hardware-config -- machineName
# manually create a disko.nix for the machine using the hardware config. # FIXME: automate this step.
nix run .#install-machine -- machineName
```

#### Updating

```bash
nix run .#deploy-machineName # FIXME: change arg to match other commands
```
