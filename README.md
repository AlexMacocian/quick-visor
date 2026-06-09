# quick-visor

A Quickshell-based display manager overlay for Hyprland.

## Usage

Install from the AUR:

```sh
paru -S quick-visor
```

Launch the display layout window:

```sh
quick-visor
```

Optionally bind a key to launch it:

```conf
bind = SUPER, D, exec, quick-visor
```

For local development, run directly from the clone:

```sh
quickshell -n -p qml/shell.qml
```

## Configuration

`~/.config/quick-visor/config.json` controls panel dimensions. Missing keys fall
back to built-in defaults, so the file can be omitted.

```json
{
  "panelWidth": 760,
  "panelHeight": 520
}
```

## Theming

`~/.config/quick-visor/theme.jsonc` controls fonts and colors. It supports JSONC
comments and reloads while quick-visor is running.

```jsonc
{
  "fontFamily": "JetBrainsMono Nerd Font",
  "fontSize": 14,
  "background": "#101010",
  "foreground": "#e6e6e6",
  "idle": "#9a9a9a",
  "accent": "#7aa2f7",
  "warning": "#f7768e",
  "overlayStrong": "#26344d",
  "overlayWeak": "#202020",
  "border": "#3a3a3a",
  "padding": 8,
  "spacing": 8,
  "radius": 12
}
```
