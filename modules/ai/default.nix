{ config, lib, pkgs, ... }: {

  options.my.ai.enable = lib.mkEnableOption "system AI configuration";

  config = lib.mkIf config.my.ai.enable {
    environment.systemPackages = [ pkgs.aichat ];
  };
}
