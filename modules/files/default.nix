{ config, lib, pkgs, ... }:
{
  options.my.files.enable = lib.mkEnableOption "file manager (yazi)";

  config = lib.mkIf (config.my.graphicalEnvironment.enable && config.my.files.enable) {
    environment.systemPackages = with pkgs; [
      yazi
    ];
  };
}