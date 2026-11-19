{ config, lib, pkgs, ... }:
{
  options.my.dev.enable = lib.mkEnableOption "development tools";

  config = lib.mkIf config.my.dev.enable {
    environment.systemPackages = with pkgs; [
      git
      neovim
      fastfetch
      ripgrep
      fd
      gcc
      nodejs
      gh
    ] ++ lib.optionals config.my.graphicalEnvironment.enable [
      vscode
    ];
  };
}