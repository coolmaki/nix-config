{ config, lib, inputs, ... }:
{
  config = lib.mkIf (config.my.graphicalEnvironment.enable) {
    home-manager.users.${config.my.user} = { config, ... }: {
      imports = [ inputs.zen-browser.homeModules.beta ];

      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
      };
    };
  };
}