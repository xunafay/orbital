{ inventory, ... }:
{
  imports = [
    ./compose.nix
  ];

  orbital.reverseProxy.reitti = {
    domain = "reitti.${inventory.domain}";
    port = 3003;
  };
}
