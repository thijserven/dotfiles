#!/usr/bin/env bash

# Apply Rectangle settings via defaults (Rectangle reads from com.knollsoft.Rectangle)

defaults write com.knollsoft.Rectangle launchOnLogin -bool true
defaults write com.knollsoft.Rectangle alternateDefaultShortcuts -bool true
defaults write com.knollsoft.Rectangle subsequentExecutionMode -int 1
defaults write com.knollsoft.Rectangle windowSnapping -int 2
defaults write com.knollsoft.Rectangle almostMaximizeHeight -float 1
defaults write com.knollsoft.Rectangle almostMaximizeWidth -float 1
defaults write com.knollsoft.Rectangle gapSize -float 2.5
defaults write com.knollsoft.Rectangle moveCursorAcrossDisplays -bool true
defaults write com.knollsoft.Rectangle unsnapRestore -int 1
defaults write com.knollsoft.Rectangle hideMenuBarIcon -bool false
defaults write com.knollsoft.Rectangle SUEnableAutomaticChecks -bool true

# Restart Rectangle to pick up the new settings
if pgrep -xq "Rectangle"; then
  killall Rectangle
  sleep 1
  open -a Rectangle
fi
