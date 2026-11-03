# Borders

JankyBorders styling for macOS windows, using Catppuccin Macchiato colors.

## Files

[executable_bordersrc](executable_bordersrc) deploys as executable `~/.config/borders/bordersrc`. Sets round 10px borders, HiDPI rendering, mauve active borders, dark inactive borders, and translucent background. Vicinae is excluded.

## Operations

Homebrew service owns login startup and `KeepAlive` crash recovery:

```sh
brew services list
brew services restart borders
```

Avoid adding another startup owner. Window layout lives in [AeroSpace](../aerospace/README.md); bar styling lives in [SketchyBar](../sketchybar/README.md).

[Application index](../README.md)
