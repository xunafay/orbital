{ config, pkgs, ... }:

let
  brightnessScript = pkgs.writeShellScriptBin "brightness" ''
    STEP=5
    MIN=0
    MAX=100
    OSD_FILE="/tmp/brightness_osd_level"
    DEVICE=amdgpu_bl2

    current=$(brightnessctl --device $DEVICE get)
    device_max=$(brightnessctl --device $DEVICE max)

    new=$(echo "scale=2; ($current / $device_max) * 100" | bc \
          | sed 's/\.[0-9]*$//' \
          | awk '{ print int(($1 + 2) / 5) * 5 }')

    current=$(echo "scale=2; ($current / $device_max) * 100" | bc \
             | sed 's/\.[0-9]*$//' \
             | awk '{ print int(($1 + 2) / 5) * 5 }')

    echo $current $device_max $new

    if [[ "$1" == "up" ]]; then
      new=$((current + STEP))
      (( new > MAX )) && new=$MAX
    elif [[ "$1" == "down" ]]; then
      new=$((current - STEP))
      (( new < MIN )) && new=$MIN
    else
      exit 1
    fi

    brightnessctl --device $DEVICE set "$new%"
    echo "$new" > "$OSD_FILE"
  '';
in
{
  home.packages = [
    brightnessScript
  ];
}
