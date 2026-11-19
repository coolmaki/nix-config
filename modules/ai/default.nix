{ config, lib, pkgs, ... }:
{
  options.my.ai.enable = lib.mkEnableOption "AI tools";

  config = lib.mkIf (config.my.graphicalEnvironment.enable && config.my.ai.enable) {
    environment.systemPackages = with pkgs; [
      opencode
    ];
  };
}