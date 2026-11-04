# Install scripts and encryption

Repository-only shell scripts live here, outside chezmoi's `home/` source state:

- `common/`: age-key bootstrap, Oh My Zsh/plugins, VS Code extensions, and mise tools.
- `macos/`: Homebrew/packages, SbarLua, Vicinae, Firefox policy, app defaults, services, and system preferences.
- `linux/`: packages, login shell, and Firefox policy.

[Lifecycle templates](../home/.chezmoiscripts/.README.md) conditionally include these scripts, preserving before/after phases and run-once/change tracking. Keep platform choices in templates and shell implementations free of Go templates. Installers using repository inputs accept `DOTFILES_ROOT`, defaulting to their repository location. Vicinae's shell entry point retains Python for safe archive validation and extraction.

Package lists live in [`macos/packages.txt`](macos/packages.txt), [`linux/packages.arch.txt`](linux/packages.arch.txt), and [`linux/packages.debian.txt`](linux/packages.debian.txt). Linux lists contain one package per line; upstream installers remain in `linux/packages.sh`. Lifecycle wrappers hash these inputs so list changes trigger installation.

[`bootstrap_age_key.sh`](common/bootstrap_age_key.sh) restores the age identity from Bitwarden before encrypted files are read. It runs through `hooks.read-source-state.pre` in [`home/.chezmoi.toml.tmpl`](../home/.chezmoi.toml.tmpl), not as a `run_once_*` script: those run too late for decryption.

## Brightness commands

Homebrew package list installs `brightness` from HEAD for Apple Silicon-compatible display brightness and `rakalex/mac-brightnessctl/mac-brightnessctl` for keyboard backlight. [SketchyBar brightness controls](../home/private_dot_config/sketchybar/README.md#brightness) use these CLIs directly through Hammerspoon, without a custom native build. Manual writes leave native auto-brightness settings unchanged. Read-only checks use `brightness -l` and `mac-brightnessctl`; set commands change live hardware.

## Identity recovery

The hook receives the vault URL, secure-note name, identity path, public recipient, and chezmoi executable from generated configuration.

- Identity: `~/.config/chezmoi/key.txt`, mode `0600`; never commit it.
- Recipient: `age1w6ry9wkku47auugknzxkeswfgpvzztgtvrvj5cx436lzuw7y2clqau58us`.
- Backup: full identity text in exactly one Bitwarden secure note named `CHEZMOI_AGE_SECRET_KEY`.
- Vault: prompted during init, default `https://vault.bitwarden.com`.

An existing regular identity file is preserved and permission-corrected; symlinks are rejected. For a missing identity, the hook installs missing CLI dependencies, authenticates, syncs the vault, and requires one exact secure-note match. It validates the recovered identity against the public recipient before publishing it atomically without overwriting an existing file. Credentials and session data do not belong in chezmoi config or Git.

On macOS the hook can install Homebrew, `bitwarden-cli`, and `jq`. On Linux it reuses `bw` or installs official Bitwarden CLI v2026.10.0 under `~/.local/bin`, checking pinned SHA-256 hashes for x86_64/arm64. Linux needs `unzip` and `sha256sum`; missing `jq` is installed via apt or pacman. Update the version and both architecture checksums together when bumping the CLI.

## Secret maintenance

Encrypted sources include [SSH](../home/private_dot_ssh/README.md) and [`env.secrets.zsh`](../home/private_dot_config/zsh/README.md). GitHub CLI's current managed file is preferences, not an encrypted authentication file.

```sh
# Add a secret without storing plaintext in source state
chezmoi add --encrypt ~/.config/some-tool/secret-file

# Edit decrypted content through chezmoi; source stays encrypted
chezmoi edit ~/.ssh/config
chezmoi edit ~/.config/zsh/env.secrets.zsh
```

Changing the public recipient does **not** re-encrypt existing `.age` files. Re-encrypt all affected files with the old identity and new recipient before rotating the local identity. Keep the old identity backed up securely until decryption with the new identity has been verified. Never place plaintext identities, decrypted secrets, or vault sessions in this repository.

To change vault selection, update `data.bitwardenServer` **and the vault URL in `hooks.read-source-state.pre.args`** in local `~/.config/chezmoi/chezmoi.toml`, or regenerate configuration through init. Change the prompt default in the source template only for future init defaults. Identity path and recipient are configured in that template.

## Troubleshooting

1. Check that the secure-note identity matches both the configured recipient and the encrypted files.
2. If the local identity is missing, run `chezmoi init --apply` to configure the hook, or `chezmoi apply` if already configured. These commands also deploy pending changes.
3. An existing identity is never replaced automatically. Back up a wrong identity securely outside the repository before removing it and retrying.
4. If the CLI is logged into another vault server, run `bw logout` manually before retrying. Remove ambiguous duplicate notes so exactly one secure note matches.

Checks from repository root, without authentication or deployment:

```sh
sh -n install/common/bootstrap_age_key.sh
```

Use syntax checks and inspect rendered wrappers without reading live encrypted sources, running installers, or invoking the bootstrap hook. Do not add or generate dotfiles tests or test infrastructure; only the Vicinae keybindings extension may have tests.
