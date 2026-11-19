{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.my.graphicalEnvironment.enable) {
    environment.systemPackages = with pkgs; [
      foot
    ];
  };
}