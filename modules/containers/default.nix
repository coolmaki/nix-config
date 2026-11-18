{ config, lib, ... }: {
  options.my.containers.enable = lib.mkEnableOption "podman containers";

  config = lib.mkIf config.my.containers.enable {
    virtualisation.podman.enable = true;
  };
}
