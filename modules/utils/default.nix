{ config, lib, pkgs, ... }:
{
  options.my.utils.enable = lib.mkEnableOption "basic utils";

  config = lib.mkIf config.my.utils.enable {
    environment.systemPackages = with pkgs; [
      unzip 
    ];
  };
}
