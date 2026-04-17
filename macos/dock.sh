#!/bin/sh

# Set the icon size to the minimum (16 pixels)
defaults write com.apple.dock tilesize -int 16

# Speed up the autohide delay (remove the pause before the Dock slides out)
defaults write com.apple.dock autohide-delay -float 0

# Speed up the animation time when showing/hiding (make it instant)
defaults write com.apple.dock autohide-time-modifier -float 0

# Use a basic "Scale" effect instead of the "Genie" effect for minimizing windows
defaults write com.apple.dock mineffect -string "scale"

# Minimize windows into their application icon (prevents cluttering the right side of the Dock)
defaults write com.apple.dock minimize-to-application -bool true

# Disable the indicator lights (dots) under running apps for a cleaner look
defaults write com.apple.dock show-process-indicators -bool false

# Customize dock conents to be as minimal as possible
dockutil --no-restart --remove all

# Restart dock
killall Dock
