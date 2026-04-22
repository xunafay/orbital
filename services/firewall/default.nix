_:
{ inputs, machineName, ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
}
