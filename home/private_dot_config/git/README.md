# Git

Global identity, optional GPG signing, aliases, ignore rules, and commit-message guidance.

## Files

| Source | Deployed role |
| --- | --- |
| [config.tmpl](config.tmpl) | `~/.config/git/config`; renders `.name`, `.email`, optional `.gpgKeyId` |
| [ignore](ignore) | Global excludes for OS/editor files and local tool state |
| [template](template) | Conventional commit message template; guidance, not validation |
| [scripts](scripts/) | Executable helpers called by Git aliases |

Defaults include `main` initial branch, `code --wait` editor, fetch pruning, histogram diffs, rerere, automatic upstream setup, and following tags on push. Commits use Git's default unsigned behavior.

## Helper aliases

| Command | Behavior |
| --- | --- |
| `git p [push args]` | [Lazy push](scripts/executable_git_lazy_push.sh): sets `origin` upstream when missing, otherwise normal push |
| `git o [path]` | [Open remote](scripts/executable_git_open_remote.sh): converts origin SSH URL to HTTPS and opens optional path using macOS `open` |
| `git rb "message"` | [Lazy rebase](scripts/executable_git_lazy_rebase.sh): soft-resets to inferred source merge-base, makes one commit, force-pushes with lease |

`git rb` rewrites branch history and can include existing staged changes. It does not verify a clean working tree or stop after every failed intermediate command. Inspect branch, working tree, and inferred base before use; do not use it on shared history without coordination. Source inference uses branch-creation reflog, upstream, `origin/HEAD`, then `develop`.

## Operations

```sh
git config --global user.name
git config --global user.email
```

Config expects `diff-so-fancy`, `$PAGER`, Git LFS, and credential helper `/usr/local/share/gcm-core/git-credential-manager`. Sourcetree merge/diff tools and `git o` contain macOS-specific paths/commands despite shared deployment. Check availability on each host. URL rewrite converts `ssh://git@github.com/` to HTTPS, not scp-style `git@github.com:` remotes.

[Application index](../README.md)
