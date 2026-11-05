# Repository guide

## Purpose

Personal dotfiles repository managed by chezmoi. Source of truth lives here; `chezmoi apply` copies rendered files into `$HOME` (not symlinks). macOS is primary; Linux support targets Debian/Ubuntu and Arch. Platform branching belongs in chezmoi templates, not runtime shell configuration.

## Layout

- `.chezmoiroot`: selects `home/` as chezmoi source state root. Files under `home/` deploy to home; this repository-only `AGENTS.md`, `README.md`, `install/`, and `scripts/` do not deploy.
- `home/.chezmoi.toml.tmpl`: init prompts, age configuration, and `hooks.read-source-state.pre` bootstrap hook.
- `home/.chezmoiignore`: controls files excluded by platform.
- `home/.chezmoiscripts/{common,macos,linux}/`: thin templates gate platforms and include plain shell implementations from `install/common/`, `install/macos/`, and `install/linux/`. Script names encode execution phase/order; `run_once_*` runs once per content hash, `run_onchange_*` reruns when content changes. Keep input hashes in wrappers; included implementation edits also change rendered hashes. Inspect rendered output without deployment or hooks.
- `home/.chezmoitemplates/vscode/`: shared VS Code settings, keybindings, and extensions used by macOS and Linux targets.
- `home/private_dot_config/`: application and shell configs deployed under `~/.config/`.
- `home/Library/`: macOS application configuration and LaunchAgents.
- `home/private_dot_ssh/`: encrypted SSH config/key material.
- `install/common/bootstrap_age_key.sh`: pre-read hook helper; restores age identity from Bitwarden.
- `install/macos/packages.txt`: macOS packages and casks, installed by `install/macos/packages.sh`.
- `install/linux/packages.{arch,debian}.txt`: native package lists, installed by `install/linux/packages.sh`; upstream installers stay in the script.

Consult `README.md` for the overview and directory index. Detailed setup and troubleshooting live in `home/README.md`, installers and encryption in `install/README.md`, lifecycle ordering in `home/.chezmoiscripts/.README.md`, and application docs beside their configs. Keep directory `README.md` files excluded from deployment through the root and recursive rules in `home/.chezmoiignore`. Use `home/.chezmoiscripts/.README.md` for script documentation: chezmoi skips dot-prefixed files before validation, but rejects ordinary `README.md` there before ignore rules apply. Link this hidden README explicitly from directory indexes.

## Bootstrap and execution order

- macOS (Apple Silicon): `/bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/thijserven/dotfiles/main/setup.sh)"`. Root `setup.sh` checks x86_64 execution and installs missing Rosetta with `softwareupdate --install-rosetta --agree-to-license` before installing missing Homebrew and chezmoi, then runs `chezmoi init --apply thijserven`. Homebrew installs missing Command Line Tools before chezmoi clones the repository; run as a normal administrator account, not root. Interactive confirmations/authentication and manual macOS privacy permissions remain required.
- Linux: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply thijserven`
- `hooks.read-source-state.pre` runs before encrypted source files are read; it invokes `install/common/bootstrap_age_key.sh`. Do not move key restoration to a `run_once_*` script: those run too late for decryption.
- Lifecycle scripts sort by relative path within each before/after phase: `common/`, `linux/`, then `macos/`; numeric prefixes order scripts within each directory. Platform gates keep Linux and macOS wrappers mutually exclusive. macOS runs `macos/run_once_before_10_install_homebrew.sh.tmpl` before `macos/run_once_before_20_install_packages.sh.tmpl`; Linux uses `linux/run_once_before_20_install_packages.sh.tmpl` with apt or pacman.
- `run_onchange_before_30_install_sbarlua.sh.tmpl` installs macOS package dependencies and Lua from source mise config, then builds pinned SbarLua against its headers before config deployment. Central mise config changes trigger rebuilds; SketchyBar uses central mise Lua. Apple Command Line Tools are required. After a Lua major-version upgrade, rebuild as documented in `home/private_dot_config/sketchybar/README.md`.
- SketchyBar brightness uses Homebrew `brightness` for the online built-in display and `rakalex/mac-brightnessctl/mac-brightnessctl` for keyboard backlight. Shared Lua parsers validate CLI output; Hammerspoon serializes manual writes. Native auto-brightness settings are neither read nor changed and do not gate manual controls. macOS may later adapt brightness. No custom native helper or build hook is required. Validate with Lua syntax checks and read-only CLI queries, never set commands.
- `run_onchange_before_40_install_vicinae_extensions.sh.tmpl` installs missing Raycast bundles for Vicinae on macOS. Its list lives in `home/private_dot_config/vicinae/extensions.txt` (one store `author/name` per line, `#` comments allowed) and its hash is embedded in the rendered wrapper to trigger `run_onchange`; existing bundles are never updated or removed. Shell entry point retains system Python 3 (Command Line Tools) for safe archive extraction and uses curl.
- `run_onchange_after_41_install_mise_tools.sh.tmpl` installs tools from `home/private_dot_config/mise/config.toml` after deployment; central defaults cover Node.js LTS, Python, Go, Ruby, Rust, Bun, and Lua. Zsh activates mise and login shells expose shims; Linux package bootstrap installs mise to `~/.local/bin`. Usage lives in `home/private_dot_config/mise/README.md`.
- `run_onchange_after_45_install_keybindings.sh.tmpl` builds and installs `vendor/keybindings` on macOS after config deployment, before desktop-service startup. Source/lockfile and central mise config hashes trigger rebuilds; Node.js uses the central mise default. Defaults read deployed custom shortcuts JSON (including manually maintained Vicinae hotkeys) and detect AeroSpace bindings. Checks: `npm test` and `npm run build` in the package directory. Vicinae itself must already be installed.
- `common/run_once_after_99_set_origin_ssh.sh.tmpl` changes this repository's GitHub HTTPS `origin` to SSH after file deployment on macOS and Linux. Other remotes stay unchanged; subsequent Git operations require GitHub SSH access.
- Script numbering guidance: `00–09` prerequisites, `10–19` package managers, `20–29` packages, `30–39` extensions/tools, `40–59` app config, `60–79` services, `80–89` OS config, `90–99` finalization.
- Desktop-services script starts Homebrew services and bootstraps missing `local.keepalive.*` LaunchAgents. Borders and SketchyBar use Homebrew services with formula-provided KeepAlive. AeroSpace, Hammerspoon, and Vicinae use `open -W -a` waiters with KeepAlive and a one-second rapid-retry throttle, covering quits and crashes without direct binary launches or polling. Reapplying leaves loaded agents alone; plist changes require bootout/bootstrap or next login. Zero downtime is not guaranteed.
- AeroSpace (`start-at-login = false`) and Hammerspoon (`hs.autoLaunch(false)`) disable native startup. Turn off Vicinae's native Launch at Login manually when migrating. Launch manually with `open -a Vicinae`, never a second binary instance or `open -n`, to avoid extension-manager termination. Stop supervision before intentional maintenance quits; see lifecycle README.
- `chezmoi apply` deploys changes; `chezmoi diff` previews them; `chezmoi status` reports source/target differences. Run-once state is tracked by chezmoi, not this repo.

## Templates and platform behavior

Use Go template syntax and chezmoi data. Important values include `.chezmoi.os` (`darwin` or `linux`), `.chezmoi.osRelease.id` (Linux distro), `.chezmoi.sourceDir` (the `home/` source state), `.chezmoi.workingTree` (repository root), `.email`, `.name`, and `.bitwardenServer`.

Keep OS-specific configuration in `.tmpl` files and use `.chezmoi.os` / `.chezmoi.osRelease.id` conditions. Avoid runtime OS checks in shell modules. Shared VS Code files belong in `.chezmoitemplates/vscode/`; keep both platform target templates aligned with shared content.

Filename conventions: `dot_` becomes a leading dot; `private_` applies restrictive target permissions; `.tmpl` renders as Go template; `.age` decrypts through chezmoi; `executable_` marks executable target files. `encrypted_` is a naming convention, not chezmoi encryption behavior by itself.

## Secrets and safety

- Age identity lives at `~/.config/chezmoi/key.txt`, mode `0600`; it must never enter Git.
- Public recipient is configured in `home/.chezmoi.toml.tmpl`; encrypted files must use matching recipient.
- The Bitwarden secure note name is `CHEZMOI_AGE_SECRET_KEY`. Bootstrap validates identity against recipient, requires one exact note match, and publishes identity automically without overwriting an existing key.
- Never commit plaintext secrets, Bitwarden credentials/session data, or generated identities. Use `chezmoi add --encrypt` or `chezmoi encrypt` for new secrets; use `chezmoi edit` for encrypted targets.
- Changing the age recipient does not re-encrypt existing `.age` files. Re-encrypt them with old identity and new recipient before rotating local identity.
- Treat `chezmoi apply` as writes to the user's home directory. Preview risky changes with `chezmoi diff`.

## Shell configuration

Zsh modules are deployed under `~/.config/zsh/` and loaded by `home/dot_zshrc`: `env.zsh.tmpl` handles environment/tool initialization, `history.zsh` history behavior, `fzf.zsh` fuzzy-finder integration, `omz.zsh.tmpl` Oh My Zsh/plugins, and `aliases.zsh.tmpl` aliases. `.zprofile.tmpl` handles login-shell setup. Preserve module boundaries and template-based platform differences.

## Shell and Lua style

Use this style by default for new and edited `.sh` and `.lua` files, including shell templates and extensionless shell entry points. Follow the readability patterns in `install/`, `home/private_dot_hammerspoon/`, and `home/private_dot_config/sketchybar/`.

- Name shell files in snake*case, including `*.sh.tmpl` templates; preserve chezmoi attribute and lifecycle prefixes (`executable*`, `run*once*`, `run*onchange*`, `before*`, `after*`) and numeric ordering.
- Use two spaces for indentation, LF line endings, a final newline, and no trailing whitespace. Preserve literal heredoc content and required tab indentation.
- Separate setup, state, functions, and execution with blank lines. Add blank lines between distinct steps within functions; avoid dense blocks and needless vertical space.
- Give cohesive steps and nontrivial callbacks descriptive names. Keep short, clear callbacks inline. Shell scripts with multiple steps should have a small `main` function showing execution order; tiny scripts need no wrapper.
- Expand multi-action one-line conditionals and loops. Split long Lua tables into readable fields, keeping small related tables compact.
- Comments explain intent, constraints, and safety, not obvious syntax. Avoid boilerplate documentation and unnecessary helpers.
- Preserve interpreter compatibility, command order, validation, error handling, cleanup, and asynchronous state/lifetimes. Do not introduce Bash-only syntax into POSIX shell scripts.
- Do not reformat unrelated files. Check edited shell with `sh -n` or `bash -n` as appropriate and Lua with `luac -p`, without deploying or invoking live app actions.

## README documentation

All `README.md` files, including hidden `.README.md`, must describe only the current state: purpose, configuration, usage, requirements, and operational constraints. Do not add changelogs, before/after comparisons, rename or replacement notes, migration/cleanup instructions for superseded versions, or narratives of iterative development (including AI-driven changes). Rewrite useful details as current behavior; keep historical context in Git history or commit messages, never in READMEs.

## Change workflow

1. Inspect relevant source and target/template conventions before editing.
2. Make the smallest change in source state under `home/`, unless changing repository tooling/docs (`scripts/`, `install/`, root docs).
3. For templates, verify both platform branches and template variables; preserve secret-handling guarantees.
4. Preview deployment with `chezmoi diff` or inspect rendered output with chezmoi commands when available. Do not apply to the live home directory unless requested.
5. Do not create or generate tests, test fixtures, test runners, or test dependencies for dotfiles in this repository. Exception: tests and test tooling are allowed within `vendor/keybindings/`; its installer may run those tests. For the rest of the repository, validate with existing syntax checks, linters, builds, and rendered-output inspection only. Keep checks isolated from the live home directory and application actions.
6. Keep README and this guide consistent when changing bootstrap, script ordering, encryption, or repository layout.

## Avoid

- Adding runtime OS detection to shell config.
- Moving age-key bootstrap after source-state reading.
- Assuming files under `home/` retain their source names or paths after deployment.
- Treating `encrypted_` prefix alone as encryption.
- Running destructive state resets or applying broad home-directory changes without user request.
