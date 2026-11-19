{ config, lib, pkgs, ... }: {
  hardware.enableRedistributableFirmware = true;

  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [ "b43" "bcma" "ssb" "brcmfmac" "brcmsmac" ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "kbd-backlight" ''
      exec ${pkgs.brightnessctl}/bin/brightnessctl -d 'smc::kbd_backlight' "$@"
    '')
  ];
}