{
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
    wifi.backend = "iwd";
  };
  networking.wireless.iwd.enable = true;
}
