{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.my.desktop;
  repo = "/home/${config.my.user}/nixos-config";
  variantDir = "${repo}/modules/desktop/variants/${cfg.variant}";
in {
  options.my.desktop = {
    enable = lib.mkEnableOption "Hyprland desktop";
    variant = lib.mkOption {
      type = lib.types.str;
      default = "minimal";
      description = "Folder under modules/desktop/variants with the Hyprland and Quickshell configs.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
    hardware.graphics.enable = true;
    security.polkit.enable = true;

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];

    environment.systemPackages = with pkgs; [
      quickshell
      foot            # terminal
      # dolphin       # file manager
      wl-clipboard    # clipboard
      cliphist        # clipboard
      brightnessctl   # screen brightness keys
      playerctl       # media keys
      opencode
    ];

    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    home-manager.users.${config.my.user} = { config, ... }: {
      imports = [ inputs.zen-browser.homeModules.beta ];

      programs.zen-browser = {
        enable = true;
	setAsDefaultBrowser = true;
      };

      xdg.configFile."hypr".source = config.lib.file.mkOutOfStoreSymlink "${variantDir}/hypr";
      xdg.configFile."quickshell".source = config.lib.file.mkOutOfStoreSymlink "${variantDir}/quickshell";
    };
  };
}
