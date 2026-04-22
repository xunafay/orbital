settings: { inventory, lib, ... }:
let
  keys = settings.keys or {};
in
{
  users.users = lib.mapAttrs (username: key: {
    isNormalUser = lib.mkDefault (username != "root");
    openssh.authorizedKeys.keys = [ key ];
  }) keys;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      AllowUsers = lib.attrNames keys;
    };
    extraConfig = "MaxAuthTries 3 \n PerSourcePenalties crash:3600s authfail:3600s max:86400s";
  };
}
