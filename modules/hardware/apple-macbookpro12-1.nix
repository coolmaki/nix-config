{ config, lib, ... }: {
  hardware.enableRedistributableFirmware = true;

  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [ "b43" "bcma" "ssb" "brcmfmac" "brcmsmac" ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "broadcom-sta" "vscode" ];

  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "broadcom-sta" ];
}
