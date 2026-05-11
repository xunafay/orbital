{ config, pkgs, ... }:

let
  apps = import ./applications.nix { inherit pkgs; };

in {
  programs.niri.settings.binds = with config.lib.niri.actions; let
    pactl = "${pkgs.pulseaudio}/bin/pactl";
    grim = "${pkgs.grim}/bin/grim";
    satty = "${pkgs.satty}/bin/satty";
    slurp = "${pkgs.slurp}/bin/slurp";
    mirror = "${pkgs.wl-mirror}/bin/wl-mirror";

    volume-up = spawn pactl [ "set-sink-volume" "@DEFAULT_SINK@" "+5%" ];
    volume-down = spawn pactl [ "set-sink-volume" "@DEFAULT_SINK@" "-5%" ];
    brightness-up = spawn "sh" [ "brightness" "up" ];
    brightness-down = spawn "sh" [ "brightness" "down" ];
    screenshot = spawn "sh" [ "-c" "${grim} -g \"$(${slurp})\" - | ${satty} -f -" ];
  in {
    "super+Return".action = spawn ["noctalia-shell" "ipc" "call" "launcher" "toggle"];
    "super+S".action = spawn ["noctalia-shell" "ipc" "call" "controlCenter" "toggle"];
    "super+Space".action = spawn ["qs" "ipc" "call" "globalIPC" "toggleStatusMenu"];
    "super+l".action = spawn ["noctalia-shell" "ipc" "call" "lockScreen" "lock"];

    "xf86audioraisevolume".action = spawn ["noctalia-shell" "ipc" "call" "volume" "increase" ];
    "xf86audiolowervolume".action = spawn ["noctalia-shell" "ipc" "call" "volume" "decrease" ];
    "xf86monbrightnessup".action = spawn ["noctalia-shell" "ipc" "call" "brightness" "increase"];
    "xf86monbrightnessdown".action = spawn ["noctalia-shell" "ipc" "call" "brightness" "decrease"];
    "control+super+xf86audioraisevolume".action = spawn ["noctalia-shell" "ipc" "call" "brightness" "increase"];
    "control+super+xf86audiolowervolume".action = spawn ["noctalia-shell" "ipc" "call" "brightness" "decrease"];

    "super+q".action = close-window;
    "super+b".action = spawn apps.browser;
    #"super+Return".action = spawn apps.terminal;
    #"super+Control+Return".action = spawn apps.appLauncher;
    "super+E".action = spawn apps.fileManager;

    "super+f".action = fullscreen-window;
    "super+t".action = toggle-window-floating;

    "super+shift+s".action = screenshot;
    #"control+shift+2".action = screenshot-window { write-to-disk = true; };

    "super+p".action = spawn mirror ["eDP-1"];

    "super+Left".action = focus-column-left;
    "super+Right".action = focus-column-right;
    "super+Down".action = focus-workspace-down;
    "super+Up".action = focus-workspace-up;

    "super+Shift+Left".action = move-column-left-or-to-monitor-left;
    "super+Shift+Right".action = move-column-right-or-to-monitor-right;
    "super+Shift+Down".action = move-column-to-workspace-down;
    "super+Shift+Up".action = move-column-to-workspace-up;

    "super+Control+Shift+Left".action = move-column-to-monitor-left;
    "super+Control+Shift+Right".action = move-column-to-monitor-right;

    # Window resizing
    "super+Control+Left".action = set-column-width "-10%";
    "super+Control+Right".action = set-column-width "+10%";
    "super+Control+Down".action = set-window-height "-10%";
    "super+Control+Up".action = set-window-height "+10%";

    # Reset window size
    "super+Control+r".action = set-column-width "50%";

    "super+1".action = focus-workspace "browser";
    "super+2".action = focus-workspace "vesktop";
  };
}
