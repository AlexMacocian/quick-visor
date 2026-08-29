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

## Persisting the layout

Applying a layout runs `hyprctl eval` with `hl.monitor{}` for each display,
which takes effect immediately but is lost when Hyprland restarts.

To make changes survive a restart, quick-visor also rewrites
`~/.config/hypr/monitors.lua` **only if that file already exists**. If the file
is absent, quick-visor leaves it alone and applies the layout at runtime only.
Pull it into your `hyprland.lua` to enable persistence:

```lua
require("monitors")
```

> Since Hyprland 0.55 the config language is Lua and `hyprctl keyword` is
> rejected outright (`keyword can't work with non-legacy parsers. Use eval.`),
> so quick-visor targets `hyprland.lua` / `monitors.lua` rather than the retired
> hyprlang `.conf` files.

