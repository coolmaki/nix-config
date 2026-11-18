{ config, lib, pkgs, ... }: {
  options.my.user = lib.mkOption {
    type = lib.types.str;
    description = "Primary user that Home Manager configures.";
  };

  config = {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.systemPackages = with pkgs; [ pciutils usbutils ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${config.my.user}.home.stateVersion = config.system.stateVersion;
  };
}
