_:
{ inputs, ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
}
