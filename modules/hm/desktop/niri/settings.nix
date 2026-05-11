{ pkgs, ... }:
{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {
      workspaces = {
        "browser" = {};
        "vesktop" = {};
      };

      prefer-no-csd = true;

      hotkey-overlay = {
        skip-at-startup = true;
      };

      layout = {

        background-color = "#00000000";

        focus-ring = {
          enable = true;
          width = 2;
          active = {
            color = "#A8AEFF";
          };
          inactive = {
            color = "#505050";
          };
        };

        gaps = 6;

        struts = {
          left = 12;
          right = 12;
          top = 12;
          bottom = 12;
        };
      };

      input = {
        keyboard.xkb = {
    	  layout = "us";
	      variant = "intl";
	    };

        touchpad = {
          click-method = "button-areas";
          dwt = true;
          dwtp = true;
          natural-scroll = true;
          scroll-method = "two-finger";
          tap = true;
          tap-button-map = "left-right-middle";
          middle-emulation = true;
          accel-profile = "adaptive";
        };
        focus-follows-mouse.enable = false;
        warp-mouse-to-focus.enable = false;
      };

      outputs = {
        "DP-2" = {
          position = { x = -1920; y = 0; };
        };
        "DP-1" = {
          position = { x = 0; y = 0; };
        };
        "HDMI-A-1" = {
          position = { x = 2560; y = 0; };
        };
      };

      cursor = {
        size = 16;
        theme = "Adwaita";
      };

      environment = {
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";

        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "niri";
        DISPLAY = ":0";
      };
    };
  };
}
