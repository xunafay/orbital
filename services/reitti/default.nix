settings:
{ inventory, ... }:
let
  name = "reitti";
in
{
  imports = [
    ./compose
  ];

  orbital.reverseProxy.${name} = {
    domain = "${name}.${inventory.domain}";
    port = 3003;
  };
}
