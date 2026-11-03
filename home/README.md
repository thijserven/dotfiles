# Managed home

`.chezmoiroot` selects this directory as chezmoi's source state. Its contents map to `$HOME`; the `home/` prefix is not deployed. chezmoi renders and copies files, rather than creating symlinks. Edit source here, preview changes, then apply deliberately.

## Directory guide

| Path                                                               | Responsibility                                                               |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| [`.chezmoi.toml.tmpl`](.chezmoi.toml.tmpl)                         | Init prompts, age settings, and pre-read bootstrap hook                      |
| [`.chezmoiignore`](.chezmoiignore)                                 | Platform exclusions and recursive `README.md` exclusion                      |
| [`.chezmoiexternal.toml.tmpl`](.chezmoiexternal.toml.tmpl)         | Pinned, checksum-verified SketchyBar icon map download on macOS              |
| [`.chezmoiscripts/`](.chezmoiscripts/.README.md)                   | Conditional wrappers for shell scripts in [`install/`](../install/README.md) |
| [`.chezmoitemplates/`](.chezmoitemplates/README.md)                | Shared VS Code templates                                                     |
| [`private_dot_config/`](private_dot_config/README.md)              | Configuration deployed to `~/.config/`                                       |
| [`dot_hammerspoon/`](dot_hammerspoon/README.md)                    | macOS automation deployed to `~/.hammerspoon/`                               |
| [`Library/`](Library/README.md)                                    | macOS application configuration                                              |
| [`private_dot_ssh/`](private_dot_ssh/README.md)                    | Encrypted SSH configuration and keys                                         |
| [`dot_zshrc`](dot_zshrc), [`dot_zprofile.tmpl`](dot_zprofile.tmpl) | [Zsh entry points](private_dot_config/zsh/README.md)                         |

## Prerequisites

- Internet access and a Bitwarden secure note named exactly `CHEZMOI_AGE_SECRET_KEY`, containing the full age identity matching the recipient in `.chezmoi.toml.tmpl`. An existing `~/.config/chezmoi/key.txt` skips vault access; its permissions are enforced as `0600`.
- **macOS:** Apple Silicon Mac, internet access, and an administrator account. Several configs assume `/opt/homebrew`. Apple Command Line Tools are needed for Git, SbarLua, and system Python 3. The age hook installs `bitwarden-cli` and `jq` when needed.
- **Linux:** Debian/Ubuntu or Arch, `curl`, and `sudo` access. Automatic Bitwarden CLI installation supports x86_64/arm64 and needs `unzip` and `sha256sum`: install `unzip coreutils` with apt or pacman first. Other architectures need a preinstalled `bw`.

These dotfiles install packages, change shell and app settings, and modify macOS defaults. Review [lifecycle scripts](.chezmoiscripts/.README.md) before applying to an existing machine.

## Bootstrap

For macOS installation, see [Getting started](../README.md#getting-started) in the root README.

Linux:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply thijserven
```

Init clones the repository into `~/.local/share/chezmoi`, asks for setup values, and saves configuration in `~/.config/chezmoi/chezmoi.toml`.

| Prompt               | Saved data        | Behavior                                  |
| -------------------- | ----------------- | ----------------------------------------- |
| Email address        | `email`           | Git identity                              |
| Full name            | `name`            | Git identity                              |
| Bitwarden server URL | `bitwardenServer` | Defaults to `https://vault.bitwarden.com` |

The pre-read hook restores the age identity before encrypted source files are read. Before-scripts install dependencies, files are deployed, and after-scripts configure applications and services. See [encryption](../install/README.md) and [script order](.chezmoiscripts/.README.md).

On Linux, package setup uses apt or pacman, installs additional tools from upstream where needed, and sets Zsh as the default shell. Arch setup runs `pacman -Syu`. Homebrew is macOS-only.

## Verify and finish setup

```sh
fastfetch
git config --global user.email
git config --global user.name
test -f ~/.ssh/config
gh auth login
```

macOS may show many permission and default-app popups during bootstrap and installation as apps open. Follow each prompt and grant requested permissions. For default-app prompts, choose the button containing **Use: XXX**, not **Keep: XXX**.

Follow the dialogs you see appear on screen and give the permissions the dialogs ask for. If permissions are granted but behavior remains broken, log out and log back in.

Set Cmux's default terminal through Settings > General > Default Terminal manually.

Optional SSH remote, from the repository checkout:

```sh
git remote set-url origin git@github.com:thijserven/dotfiles.git
```

## Daily usage

```sh
chezmoi edit ~/.zshrc                 # Edit source; no apply unless requested
chezmoi diff                         # Preview deployment
chezmoi status                       # Report source/target differences
chezmoi apply ~/.zshrc                # Deploy one file
chezmoi apply                        # Deploy all changes and eligible scripts
chezmoi edit --apply ~/.zshrc         # Edit, then deploy
chezmoi update                       # Pull and apply upstream changes
```

`cm` is the shell alias for `chezmoi`; `cm cd` opens the source directory. Commit reviewed source changes from the repository root.

Add existing files with `chezmoi add ~/.config/some-tool/config`; use `chezmoi add --encrypt` for secrets. To import deliberate live-file edits, use `chezmoi re-add ~/.config/some-tool/config`. This overwrites the source copy; review its diff before committing.

Ignore patterns in `.chezmoiignore` use **target paths**, for example `.config/some-tool/`, not `private_dot_config/some-tool/`. `README.md` and `**/README.md` keep directory docs out of the managed home, including on both platforms.

## Source naming and templates

| Name                         | Meaning                                                                 |
| ---------------------------- | ----------------------------------------------------------------------- |
| `dot_`                       | Leading dot in target name                                              |
| `private_`                   | Restrictive target permissions; directories retain traversal permission |
| `executable_`                | Executable target file                                                  |
| `.tmpl`                      | Rendered Go template                                                    |
| `.age`                       | Age-encrypted content                                                   |
| `encrypted_`                 | Naming convention, not encryption by itself                             |
| `run_once_`, `run_onchange_` | [Lifecycle scripts](.chezmoiscripts/.README.md)                         |

Platform branching belongs in templates, not runtime shell modules:

```gotemplate
{{- if eq .chezmoi.os "darwin" }}
# macOS
{{- else if eq .chezmoi.os "linux" }}
{{-   if eq .chezmoi.osRelease.id "arch" }}
# Arch
{{-   else }}
# Debian/Ubuntu
{{-   end }}
{{- end }}
```

| Variable                             | Meaning                                                        |
| ------------------------------------ | -------------------------------------------------------------- |
| `.chezmoi.os`                        | `darwin` or `linux`                                            |
| `.chezmoi.osRelease.id`              | Linux distribution ID                                          |
| `.chezmoi.sourceDir`                 | Source state directory, normally `~/.local/share/chezmoi/home` |
| `.chezmoi.workingTree`               | Repository root; use for `install/` and `scripts/`             |
| `.chezmoi.homeDir`                   | Target home directory                                          |
| `.email`, `.name`                    | Saved Git identity                                             |
| `.bitwardenServer`, `.bitwardenNote` | Vault URL and secure-note name                                 |

## Troubleshooting

- **Age decryption fails:** follow [identity recovery](../install/README.md#troubleshooting). Never commit or overwrite an identity to work around an error.
- **Init prompts repeat:** local chezmoi config is missing or incomplete. Re-run `chezmoi init --apply thijserven` to restore prompts and hook; this also applies changes.
- **Packages not installing:** run-once scripts do not reconcile package lists on every apply. On macOS run `sh "$HOME/.local/share/chezmoi/install/macos/packages.sh"`; on Linux review the package script and rerun needed commands manually.
- **Unexpected diff:** `chezmoi diff` compares source and live target. Choose whether to deploy source with `apply` or import deliberate target edits with scoped `re-add`; neither direction is an automatic merge.
- **Shell, plugins, or signing fail:** see [Zsh troubleshooting](private_dot_config/zsh/README.md#troubleshooting).
- **Desktop startup or Lua errors:** see [lifecycle scripts](.chezmoiscripts/.README.md) and [SketchyBar](private_dot_config/sketchybar/README.md).
