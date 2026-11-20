{ config, lib, pkgs, ... }:
let
  cfg = config.my.keybind;
  repo = config.my.repo;
in {
  options.my.keybind.enable = lib.mkEnableOption ''
    Custom keybinds.
    Remaps Super+C/V/X/S/A/F to Ctrl+C/V/X/S/A/F in GUI apps
    (terminals excluded — they handle copy/paste natively).
    Config is hot-reloaded on file change (no rebuild needed).
  '';

  config = lib.mkIf cfg.enable {
    services.xremap = {
      enable = true;
      package = pkgs.xremap;
      serviceMode = "user";
      yamlConfig = builtins.readFile ./config/xremap.yml;
      userName = config.my.user;
      watch = true;
      extraArgs = [
        "--watch=config"
        "--desktop" "hypr"
        "/home/${config.my.user}/.config/xremap/config.yml"
      ];
    };

    # Override systemd sandboxing — xremap needs /dev/uinput write access
    systemd.user.services.xremap.serviceConfig = {
      ProtectSystem = lib.mkForce false;
      PrivateDevices = lib.mkForce false;
    };

    home-manager.users.${config.my.user} = { config, ... }: {
      xdg.configFile."xremap/config.yml".source =
        config.lib.file.mkOutOfStoreSymlink "${repo}/modules/keybind/config/xremap.yml";
    };
  };
}
