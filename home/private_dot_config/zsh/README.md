# Zsh

Deploys to `~/.config/zsh/`. [`home/dot_zshrc`](../../dot_zshrc) becomes `~/.zshrc` and sources this directory's `.zshrc`. [`dot_zprofile.tmpl`](../../dot_zprofile.tmpl) handles login-shell setup: optional `.profile`, Homebrew on macOS, installed OrbStack integration, and `~/.local/bin`.

## Load order

[`dot_zshrc`](dot_zshrc) sources these modules in order when present:

| Source                                 | Responsibility                                                                   |
| -------------------------------------- | -------------------------------------------------------------------------------- |
| [`env.zsh.tmpl`](env.zsh.tmpl)         | PATH, VS Code editor, locale, Starship, zoxide, mise, TheFuck, direnv |
| `encrypted_env.secrets.zsh.age`        | Age-encrypted environment secrets, deployed as `env.secrets.zsh`                 |
| [`history.zsh`](history.zsh)           | One-million-entry history, timestamps, sharing, deduplication                    |
| [`fzf.zsh`](fzf.zsh)                   | fzf bindings, fd searches, previews, yazi wrapper                                |
| [`omz.zsh.tmpl`](omz.zsh.tmpl)         | Oh My Zsh, plugins, automatic updates; no theme because Starship owns prompt     |
| [`aliases.zsh.tmpl`](aliases.zsh.tmpl) | Command shortcuts and platform-specific aliases                                  |

Keep these boundaries intact. Platform differences belong in chezmoi templates, not runtime OS checks. Oh My Zsh and external plugins are installed by the [package script](../../.chezmoiscripts/.README.md).

## Runtimes with mise

[`../mise/config.toml`](../mise/config.toml) owns central Node.js, Python, Go, Ruby, Rust, and Bun defaults. Interactive activation switches versions for projects; login shells also expose mise shims. direnv stays last so virtual environments can override PATH. macOS prefers Homebrew's mise over stale user-local installations.

See [mise usage](../mise/README.md) for installation, central version changes, project overrides, and scripts/editors.

## Finding files and navigating

- `Ctrl+T`: fuzzy-find files using fd, with bat preview. Enter opens each selected file in VS Code alongside its Git repository root (including worktrees); files outside Git repositories open on their own.
- `Alt+C`: fuzzy-find directories with eza tree preview.
- `Ctrl+R`: search command history.
- `y`: launch yazi and change the shell's directory to its final location on exit.

fd includes hidden files and excludes `.git`. Prompt settings live under [Starship](../starship/README.md); previews use [bat](../bat/README.md) and [eza](../eza/README.md).

## Changes and secrets

```sh
chezmoi edit ~/.config/zsh/aliases.zsh
chezmoi edit ~/.config/zsh/env.secrets.zsh
chezmoi diff
chezmoi apply ~/.config/zsh/aliases.zsh
```

Use chezmoi to edit encrypted secrets; never write plaintext into source state. See [encryption](../../../install/common/README.md). Start a new shell after deployment to reload everything.

## Troubleshooting

- Missing syntax highlighting: package setup installs `~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting`. If absent, clone `https://github.com/zsh-users/zsh-syntax-highlighting` there, then start a new shell. `zsh-autosuggestions` is another external plugin.
- Linux still starts another shell: check `command -v zsh`, run `chsh -s /usr/bin/zsh` if that is the installed path, then log out and back in.
- Missing command errors during startup: environment initialization expects installed tools. Check package-script completion before editing around missing dependencies.
