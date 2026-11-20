{ config, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../hardware/apple-macbookpro12-1.nix
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = "latte";
  networking.networkmanager.enable = true;

  time.timeZone = "Australia/Brisbane";
  i18n.defaultLocale = "en_AU.UTF-8";
  console.keyMap = "us";

  users.users.maki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    initialPassword = "2cool4arch";
  };

  system.stateVersion = "26.05";

  my = {
    user = "maki";
    graphicalEnvironment = {
      enable = true;
      variant = "minimal";
    };
    utils.enable = true;
    ai.enable = true;
    dev.enable = true;
    containers.enable = true;
    terminal.enable = true;
    learning.enable = true;
    theme.enable = true;
  };
}
