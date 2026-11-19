# Architecture

## Design

### Option namespace

All user-facing options live under `my.*`:

| Option | Module | Description |
|--------|--------|-------------|
| `my.user` | root | Primary user for Home Manager |
| `my.graphicalEnvironment.enable` | root | Master gate for all GUI-dependent config |
| `my.graphicalEnvironment.variant` | root | Which `ui/` subdirectory to use |
| `my.ai.enable` | ai | AI tools (requires graphical environment) |
| `my.dev.enable` | dev | Development tools |
| `my.containers.enable` | containers | Podman |
| `my.learning.enable` | learning | Learning tools (requires graphical environment) |

### The graphical environment gate

`my.graphicalEnvironment.enable` is defined in the root module (`modules/default.nix`).
It is the single source of truth — every module that needs a display server or Wayland
compositor checks this option.

Modules handle the gate in one of two ways:

- **Entire module gated**: The module's config block is wrapped in
  `lib.mkIf config.my.graphicalEnvironment.enable`. Used when all packages in the
  module require a GUI (e.g., `browser`, `terminal`, `learning`).

- **Partial gating**: The module includes both CLI and GUI packages. CLI tools are
  always available; GUI packages are added with `lib.optionals`:
  ```nix
  environment.systemPackages = [
    git  # always
  ] ++ lib.optionals config.my.graphicalEnvironment.enable [
    vscode  # GUI only
  ];
  ```

### Module conventions

- Each module lives in `modules/<name>/default.nix`
- Modules define their own `my.<name>.enable` option
- Modules that require a graphical environment check `config.my.graphicalEnvironment.enable`
- Hardware-specific configs live in `hardware/` (repo root)
- Host configs in `hosts/<hostname>/` set `my.*` values and import hardware modules

### Data flow

```
flake.nix
  └─ nixosSystem
       ├─ home-manager.nixosModules.home-manager
       ├─ modules/default.nix          (root — imports everything below)
       │    ├─ whitelist
       │    ├─ ai
       │    ├─ dev
       │    ├─ containers
       │    ├─ browser
       │    ├─ terminal
       │    └─ learning
       └─ hosts/latte                  (sets my.* values)
            └─ hardware/apple-macbookpro12-1.nix
```

### Adding a new module

1. Create `modules/<name>/default.nix`
2. Define `options.my.<name>.enable = lib.mkEnableOption "..."`
3. If it requires a GUI, gate with `lib.mkIf config.my.graphicalEnvironment.enable`
4. Add to the `imports` list in `modules/default.nix`
5. Set `my.<name>.enable = true` in the host config
6. If the module pulls in unfree packages, add them to `modules/whitelist/default.nix`

### Adding a new graphical variant

1. Create `ui/<variant>/hypr/` and `ui/<variant>/quickshell/` directories
2. Set `my.graphicalEnvironment.variant = "<variant>"` in the host config

## Module dependency graph

```
root (modules/default.nix)
 ├── Always imported:
 │    ├── whitelist
 │    ├── dev (partial gate)
 │    └── containers
 └── Gated on graphicalEnvironment.enable:
      ├── ai
      ├── browser
      ├── terminal
      └── learning
```