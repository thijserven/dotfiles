# GitHub CLI

GitHub CLI preferences; authentication remains separate.

## Files

[private_config.yml](private_config.yml) deploys to `~/.config/gh/config.yml` with restrictive permissions. Uses HTTPS Git transport, interactive prompts, and `gh co` as alias for `gh pr checkout`. Editor, pager, and browser defer to environment/defaults.

## Usage

```sh
gh auth login
gh auth status
gh co 123
```

No encrypted `hosts.yml` is currently tracked in this directory. Do not add plaintext authentication tokens to Git; use chezmoi encryption if tracking credentials. See [repository encryption guidance](../../../README.md).

[Git configuration](../git/README.md) controls separate Git aliases and credential-helper settings.

[Application index](../README.md)
