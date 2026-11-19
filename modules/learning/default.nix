{ config, lib, pkgs, ... }:
{
  options.my.learning.enable = lib.mkEnableOption "learning tools";

  config = lib.mkIf (config.my.graphicalEnvironment.enable && config.my.learning.enable) {
    environment.systemPackages = with pkgs; [
      obsidian
      projectlibre
    ];
  };
}