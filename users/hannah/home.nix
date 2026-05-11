{ self, inputs, pkgs, ... }:
{
  users.users.hannah = {
    isNormalUser = true;
    description = "Hannah Witvrouwen";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs; [
    ];
  };

  imports = [
    self.inputs.home-manager.nixosModules.default
    ./ssh.nix
    ../../modules/virtualization/qemu.nix
    ../../modules/unfree.nix
    ../../modules/software
    ../../modules/fonts.nix
  ];

  home-manager.extraSpecialArgs = {
    inherit inputs self;
  };

  home-manager.users.hannah = {
    imports = [
      ../../modules/hm/bash
      ../../modules/hm/git
      ../../modules/hm/ghostty
      ../../modules/hm/desktop
      ../../modules/hm/neovim.nix
      ../../modules/hm/dotnet.nix
      ../../modules/hm/orbital.nix
      ../../modules/hm/teams.nix
      ../../modules/hm/discord.nix
      ../../modules/hm/spotify.nix
      ../../modules/hm/zen-browser
    ];

    git.user.name = "Hannah Witvrouwen";
    git.user.email = "hannah.witvrouwen@gmail.com";

    home = {
      sessionPath = [
        "$HOME/.local/bin"
      ];

      sessionVariables = {
        QML2_IMPORT_PATH = "${pkgs.kdePackages.qt5compat}/lib/qt-6/qml"; # quick fix for quickshell, should be fixed with an overlay
      };

      file = {
        ".face.icon" = {
            source = ./assets/profile.png;
            recursive = true;
            force = true;
        };
        ".wallpapers" = {
          source = ./assets/wallpapers;
          recursive = true;
          force = true;
        };
      };

      homeDirectory = "/home/hannah";
      packages = with pkgs; [
        vivaldi
        steam
        fastfetch
        discord
        obsidian
        spotify
        playerctl
        teams-for-linux
      ];

      stateVersion = "25.11";
    };
  };
}
