{ inputs, ... }:
{
  environment.systemPackages = [
    inputs.compose2nix.packages.x86_64-linux.default
  ];

  virtualisation = {
    docker.enable = false;
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.dnsname.enable = true;
    };
  };
}
