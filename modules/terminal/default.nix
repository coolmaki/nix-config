{ config, lib, pkgs, ... }:
let
  cfg = config.my.terminal;
  repo = "/home/${config.my.user}/nixos-config";
in {
  options.my.terminal = {
    enable = lib.mkEnableOption "terminal configuration (zsh, starship, and terminal emulator)";
    prompt = lib.mkOption {
      type = lib.types.enum [ "starship" ];
      default = "starship";
      description = "Which powerline prompt to use";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── System-wide: zsh as default shell ──
    programs.zsh.enable = true;
    users.users.${config.my.user}.shell = pkgs.zsh;

    # ── Per-user: zsh with autocomplete, suggestions, and starship ──
    home-manager.users.${config.my.user} = { config, pkgs, ... }: {
      home.sessionVariables.SHELL = "${pkgs.zsh}/bin/zsh";
      home.packages = [ pkgs.starship ];

      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        autosuggestion.highlight = "fg=#585b70";
        syntaxHighlighting.enable = true;
        initContent = ''
          eval "$(starship init zsh)"
          if [ -n "$GHOSTTY" ]; then
            source "${pkgs.ghostty}/share/ghostty/shell-integration/zsh/ghostty-integration"
          fi
        '';
      };

      xdg.configFile."starship.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${repo}/modules/terminal/config/starship.toml";
      xdg.configFile."ghostty/config".source =
        config.lib.file.mkOutOfStoreSymlink "${repo}/modules/terminal/config/ghostty";
    };

    # ── Terminal emulator (GUI only) ──
    environment.systemPackages = lib.optionals config.my.graphicalEnvironment.enable [
      pkgs.foot
      pkgs.ghostty
      pkgs.yazi
    ];
  };
}
