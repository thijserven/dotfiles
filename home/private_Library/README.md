# macOS Library

Maps to `~/Library/` on macOS. Linux excludes `Library/Application Support` and `Library/LaunchAgents` through [`.chezmoiignore`](../.chezmoiignore).

## Contents

[`Application Support/Code/User/`](Application%20Support/Code/User/) contains thin templates for VS Code settings and keybindings. Their shared source lives in [`.chezmoitemplates/vscode/`](../.chezmoitemplates/README.md); edit those shared files to keep macOS and Linux aligned.

[LaunchAgents](LaunchAgents/) supervise AeroSpace, Hammerspoon, and Vicinae through LaunchServices, restarting after quit/crash without launching separate app binaries. [Desktop startup](../.chezmoiscripts/.README.md#desktop-startup-on-macos) covers deployment, retry timing, and maintenance. Borders and SketchyBar remain Homebrew services. Caps Lock remapping belongs to [Hammerspoon](../private_dot_hammerspoon/README.md).

Directory documentation stays in Git and is excluded from deployment.
