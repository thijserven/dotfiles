# Application configuration

Chezmoi source for `~/.config/`. Source filenames encode permissions and template rendering; deployed names differ. Edit source here, preview with `chezmoi diff`. See [repository setup](../../README.md) for bootstrap and encryption.

| Directory | Purpose |
| --- | --- |
| [aerospace](aerospace/README.md) | macOS tiling, workspaces, SketchyBar events |
| [bat](bat/README.md) | Syntax highlighting and custom theme |
| [borders](borders/README.md) | macOS window borders |
| [Code](Code/README.md) | Linux VS Code wrappers and shared configuration |
| [eza](eza/README.md) | File-listing colors |
| [fastfetch](fastfetch/README.md) | System-information display |
| [firefox](firefox/README.md) | Browser policies and deployment |
| [gh](gh/README.md) | GitHub CLI preferences |
| [ghostty](ghostty/README.md) | Terminal appearance and shortcuts |
| [git](git/README.md) | Identity, signing, aliases, helper scripts |
| [opencode](opencode/README.md) | OpenCode configuration and opt-in engineering workflow |
| [sketchybar](sketchybar/README.md) | macOS status bar and SbarLua operations |
| [starship](starship/README.md) | Shell prompt |
| [vicinae](vicinae/README.md) | Launcher settings, extensions, startup |
| [zsh](zsh/README.md) | Shell modules and integrations |

Platform exclusions live in [`.chezmoiignore`](../.chezmoiignore). `Code` targets Linux; AeroSpace, SketchyBar, and Vicinae are excluded on Linux. Other platform-specific behavior belongs in templates and [deployment scripts](../.chezmoiscripts/).
