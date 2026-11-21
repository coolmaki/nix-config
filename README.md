# Nix Config

Modular NixOS configuration with Home Manager integration.

## Quick start

```bash
sudo nixos-rebuild switch --flake .#latte
```

## Structure

```
nixos-config/
├── flake.nix                  # Entry point — nixosSystem for each host
├── ui/                        # Hyprland + Quickshell config
├── hardware/                  # Per-machine hardware modules
├── hosts/                     # Host definitions (one directory per machine)
│   └── latte/
│       ├── default.nix        # Host-specific config + my.* options
│       └── hardware-configuration.nix
└── modules/                   # Feature modules (see modules/README.md)
    ├── default.nix            # Root — core system + graphical environment
    ├── ai/                    # AI tools
    ├── browser/               # Web browser
    ├── containers/            # Container runtime
    ├── dev/                   # Development tools
    ├── learning/              # Learning tools
    ├── terminal/              # Terminal emulator
    └── whitelist/             # License whitelisting
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions and conventions.