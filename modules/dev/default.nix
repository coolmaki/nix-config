{ config, lib, pkgs, ... }: {
  options.my.dev.enable = lib.mkEnableOption "development tools";

  config = lib.mkIf config.my.dev.enable {
    environment.systemPackages = with pkgs; [
      git
      neovim
      ripgrep
      fd
      gcc
      nodejs
    ];
  };
}
