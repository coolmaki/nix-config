{ config, lib, pkgs, ... }: {
  options.my.theme.enable = lib.mkEnableOption "system theming (GTK, icons, etc.)";

  config = lib.mkIf (config.my.graphicalEnvironment.enable && config.my.theme.enable) {
    home-manager.users.${config.my.user} = {
      gtk = {
        enable = true;
        theme = {
          name = "Catppuccin-Mocha-Mauve";
          package = pkgs.catppuccin-gtk;
        };
      };
    };
  };
}