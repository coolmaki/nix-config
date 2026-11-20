# Modules

| Module | Path | Requires GUI? | Description |
|--------|------|---------------|-------------|
| root | `modules/default.nix` | — | Core system settings, graphical environment (Hyprland, Quickshell, SDDM) |
| ai | `modules/ai/` | Yes | AI coding tools (opencode) |
| browser | `modules/browser/` | Yes | Web browser (zen-browser) |
| containers | `modules/containers/` | No | Container runtime (podman) |
| dev | `modules/dev/` | Partial | Development tools — CLI always, vscode gated on GUI |
| learning | `modules/learning/` | Yes | Learning tools (obsidian, projectlibre) |
| terminal | `modules/terminal/` | Partial | Shell (zsh), prompt (starship), plugins, terminal emulator (foot) |
| theme | `modules/theme/` | Yes | System theming (GTK, icons) |
| whitelist | `modules/whitelist/` | No | Unfree/insecure package license whitelisting |