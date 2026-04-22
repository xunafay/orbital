_:
{ inputs, machine, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops.age.keyFile = "/etc/sops/age/keys.txt";
  sops.age.sshKeyPaths = [];

  sops.secrets."ssh_host_ed25519_key" = {
    sopsFile = ../../secrets/machines/${machine.name}/ssh/ssh_host_ed25519_key.yaml;
    format = "yaml";
    key = "data";
    path = "/etc/ssh/ssh_host_ed25519_key";
    owner = "root";
    mode = "0600";
  };

  services.openssh.hostKeys = [
    {
      type = "ed25519";
      path = "/etc/ssh/ssh_host_ed25519_key";
    }
  ];
}
