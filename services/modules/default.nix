settings:
{ inputs, ... }:
let
  modules = settings.modules or [];
in
{
  imports = modules;
}
