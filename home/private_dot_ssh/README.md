# SSH

Maps to `~/.ssh/` with restrictive permissions. Configuration and key material stay age-encrypted in source state; `private_keys/` maps to `~/.ssh/keys/`. See [bootstrap and encryption](../../install/README.md) for identity recovery and recipient rotation.

## Maintenance

```sh
# Edit configuration through chezmoi's decrypt/edit/encrypt workflow
chezmoi edit ~/.ssh/config

# Add new secret key material encrypted
chezmoi add --encrypt ~/.ssh/keys/example

# Review before deployment
chezmoi diff ~/.ssh/config
chezmoi apply ~/.ssh/config
```

Never commit plaintext private keys or decrypted SSH configuration. `encrypted_` is only a naming convention; verify new secret sources are age-encrypted. The age identity belongs at `~/.config/chezmoi/key.txt`, never here.

`README.md` stays repository-only through the recursive ignore rule.
