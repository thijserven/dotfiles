# Keybindings

Native Vicinae extension based on [Shortcut Library by rhrabun](https://github.com/raycast/extensions/tree/ff678517a421538e8533030aa447420631886169/extensions/shortcut-library) (MIT). Provides grouped, searchable keybindings from read-only configuration sources. Does not modify the store extension.

## Install

macOS `chezmoi apply` automatically installs this extension after config deployment and before desktop-service startup. The [installer](../../home/.chezmoiscripts/macos/run_onchange_after_45_install_keybindings.sh.tmpl) uses the central mise Node.js LTS default, installs locked npm packages, runs checks, and builds into Vicinae's extension directory. Source changes trigger rebuilds; shortcut-data changes do not need a rebuild. Vicinae itself must already be installed; this script does not launch it.

Manual installation requires Node.js LTS (or another Node.js version supported by the locked dependencies) and npm. From this directory:

```sh
npm ci
npm test
npm run build
npx vici build
```

`npm run build` validates and builds locally into ignored `dist/`. Final command installs into Vicinae's extension directory using its native CLI. Reopen Vicinae if **Browse Keybindings** does not appear. Development: `npm run dev` with Vicinae running.

## Sources

Set paths and detection toggles in extension preferences. Absolute paths and `~/` paths work.

- **Shortcuts JSON** defaults to `~/.config/vicinae/keybindings.json`, deployed by chezmoi. Use it for custom keybindings, including manually maintained Vicinae shortcuts. Empty disables it. Supports `category`, `title`, `keys`, and optional string-array `tags`. Entries with `source: "aerospace"` and `id: "mode.key"` (for example, `main.alt-h`) override detected AeroSpace bindings instead of adding entries. Overrides replace title and keys, retain the detected category unless specified, and merge tags. No import needed.
- **SketchyBar JSON** defaults to `~/.cache/sketchybar/keybindings.json`, published dynamically by SketchyBar. Uses the same custom JSON format; popup rows describe current Hyper+1 through Hyper+9 and Hyper+0 slot bindings. Independent of **Shortcuts JSON**; empty disables it. Missing cache file is normal and silent. Malformed JSON or invalid rows produce warnings without hiding other sources.
- **AeroSpace** auto-detects `~/.config/aerospace/aerospace.toml`, then `~/.aerospace.toml`. To read repo edits immediately, set **AeroSpace TOML** to `~/.local/share/chezmoi/home/private_dot_config/aerospace/aerospace.toml`. All `[mode.<name>.binding]` tables are parsed with TOML support, including command arrays. Command text becomes the title; modes become categories. Commands are never executed.

Every command mount rereads files. **Reload Files** refreshes an already open view. Categories filter results; titles, keys, categories and tags are searchable. **Copy Keys** copies displayed keys; **Open Source File** opens its source. Errors stay visible without hiding healthy sources; no stale stored imports are used. Custom key strings are displayed as written.

No background watcher, automatic execution, or configuration writes. Default sources use deployed files: run `chezmoi apply` after repo JSON/AeroSpace edits. For immediate source-tree reads, override paths in extension preferences. No first-run preference setup or import needed; opening **Browse Keybindings** reads custom shortcuts, optional SketchyBar shortcuts, and detected AeroSpace bindings automatically. Existing explicit preference overrides remain unchanged.

## Checks

```sh
npm test
npm run typecheck
npm run build
```

Tests cover JSON validation, optional SketchyBar cache reads and malformed rows, TOML modes and arrays, AeroSpace overrides, fresh reads, and partial-source failure. Tests bundle through esbuild, matching production dependency resolution. `npm run build` also loads the compiled command with only runtime-provided externals, catching missing bundled dependencies before installation.
