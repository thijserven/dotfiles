# mise

[`config.toml`](config.toml) deploys to `~/.config/mise/config.toml`: central user-level defaults for Node.js, Python, Go, Ruby, Rust, Bun, and Lua. Node.js follows LTS; other runtimes use pinned versions. npm ships with Node.js. Python and Ruby use precompiled-only installs; Node.js and Python version files are enabled. Other CLI tools use package installers.

## Install and verify

`chezmoi apply` deploys config, then installs its runtimes. macOS installs mise through Homebrew; Linux installs it under `~/.local/bin`. The installer resolves config from the global mise directory, not whichever project invoked chezmoi. Vicinae's keybindings build uses the same central Node.js default.

```sh
mise doctor
mise ls
mise config ls
mise which node
mise which python
node --version
python --version
```

Interactive Zsh activates mise and switches runtimes when entering projects. Login Zsh adds mise shims to PATH, so login-shell commands work without interactive activation. Restart with `exec zsh -l` after deployment. direnv runs last; activated virtual environments can intentionally override Python.

## Change central versions

Edit this repository's `home/private_dot_config/mise/config.toml`, then preview and deploy:

```sh
chezmoi diff
chezmoi apply
```

Use exact versions for reproducibility; requests such as `lts`, `latest`, or `3.14` permit updates within that range. `mise install` installs missing versions; `mise upgrade node` moves to the newest allowed Node.js LTS. Exact pins require editing config before an upgrade can move beyond them. Old versions remain until explicitly removed.

`mise use --global python@3.14` edits the **deployed** config, not this repository. Prefer editing source; if using global mise commands, copy the resulting changes back before the next apply.

## Project versions and Python environments

Central defaults apply unless a project overrides them. Keep project requirements in the project's own config:

```sh
mise use node@22 python@3.13    # writes project mise.toml and installs versions
mise install                  # installs versions requested by current project
mise current                  # shows effective versions in this directory
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

Node.js `.nvmrc` / `.node-version` and Python `.python-version` files are enabled. Inspect `mise config ls` when unexpected project or parent configs change versions. Projects without overrides use central defaults. To require central versions everywhere, remove project overrides and disable idiomatic version files; do not duplicate runtime pins in shell config.

Use virtual environments for Python dependencies, not system-wide `pip install`. npm global packages belong to their Node.js installation; reinstall them after changing Node.js versions, or declare needed CLI tools centrally using mise backends.

## Scripts, editors, and system boundaries

Noninteractive scripts do not normally read `.zshrc`; use mise explicitly:

```sh
mise exec -- node script.js
mise exec -- python script.py
# Force central defaults rather than current project's overrides:
mise -C "${XDG_CONFIG_HOME:-$HOME/.config}/mise" exec -- node --version
```

VS Code integrated terminals load interactive Zsh. Launch `code .` from an activated shell when editor tasks/extensions need its runtime PATH. Already-running GUI apps may retain an old environment; fully quit and reopen them. For Python projects, select `.venv/bin/python` in the editor. Finder-launched apps and services do not automatically source shell config: configure their commands with `mise exec` or add `~/.local/share/mise/shims` to their PATH. If `MISE_DATA_DIR` is customized, use its `shims` directory instead.

This is user-level runtime management, **not replacement of macOS/Linux system interpreters**. Keep `/usr/bin/python3` for bootstrap. SbarLua builds against mise Lua headers; SketchyBar runs the same central mise Lua. Homebrew dependencies may still install their own runtimes; mise controls user command selection through PATH, not dependency internals. Never remove OS interpreters or Homebrew dependency runtimes to force exclusivity.

Check runtime selection with `type -a mise node python python3 go ruby rustc bun`. Avoid adding `~/.cargo/bin`, other runtime-manager shims, or version-specific runtime paths ahead of mise. System services and absolute interpreter paths remain outside mise's control.
