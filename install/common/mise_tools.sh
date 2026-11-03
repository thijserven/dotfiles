#!/bin/sh
set -eu

# Resolve central defaults, not overrides from chezmoi's invocation directory.
mise -C "${XDG_CONFIG_HOME:-$HOME/.config}/mise" install
