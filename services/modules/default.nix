settings:
{ inputs, machineName, ... }:
let
  modules = settings.modules or [];
in
{
  imports = modules;
}
