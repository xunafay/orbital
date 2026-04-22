_:
{ inputs, machineName, ... }:
{
  networking.firewall = {
    allowedTCPPorts = [ 57621 22 ]; # spotify device discovery
    allowedUDPPorts = [ 5353 ]; # chromecast
  };
}

