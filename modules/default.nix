{ config, lib, pkgs, ... }:
let
  cfg = config.my.graphicalEnvironment;
  repo = config.my.repo;
  variantDir = "${repo}/ui/${cfg.variant}";
in {
  imports = [
    ./whitelist
    ./utils
    ./ai
    ./dev
    ./containers
    ./browser
    ./terminal
    ./learning
    ./theme
    ./keybind
  ];

  # ── Options ────────────────────────────────────────────────────────────

  options.my.user = lib.mkOption {
    type = lib.types.str;
    description = "Primary user that Home Manager configures.";
  };

  options.my.repo = lib.mkOption {
    type = lib.types.str;
    default = "/home/${config.my.user}/nixos-config";
    description = "Path to the nixos-config repository.";
  };

  options.my.graphicalEnvironment = {
    enable = lib.mkEnableOption "graphical environment (Hyprland, Wayland, Quickshell, etc.)";
    variant = lib.mkOption {
      type = lib.types.str;
      default = "minimal";
      description = "Folder under ui/ with the Hyprland and Quickshell configs.";
    };
  };

  # ── Config ─────────────────────────────────────────────────────────────

  config = lib.mkMerge [
    # Core (always active)
    {
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      environment.systemPackages = with pkgs; [ pciutils usbutils ];

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${config.my.user}.home.stateVersion = config.system.stateVersion;
    }

    # Graphical environment (gated)
    (lib.mkIf cfg.enable {
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
        wl-clipboard
        cliphist
        brightnessctl
        playerctl
      ];

      services.pipewire = {
        enable = true;
        pulse.enable = true;
      };

      home-manager.users.${config.my.user} = { config, ... }: {
        xdg.configFile."hypr".source = config.lib.file.mkOutOfStoreSymlink "${variantDir}/hypr";
        xdg.configFile."quickshell".source = config.lib.file.mkOutOfStoreSymlink "${variantDir}/quickshell";
      };
    })
  ];
}
