#!/usr/bin/env bash

COMPUTER_NAME="mac"
LANGUAGES=(en nl)
LOCALE="en_US@currency=EUR"
MEASUREMENT_UNITS="Centimeters"
SCREENSHOTS_FOLDER="${HOME}/Screenshots"
WALLPAPER="${HOME}/.local/share/chezmoi/install/assets/wallpaper.webp"

# Computer & Host name
configure_computer_name() {
    # Set computer name (as done via System Preferences → Sharing)
    sudo scutil --set ComputerName "$COMPUTER_NAME"
    sudo scutil --set HostName "$COMPUTER_NAME"
    sudo scutil --set LocalHostName "$COMPUTER_NAME"
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"
}

# Localization
configure_localization() {
    # Set language and text formats
    defaults write NSGlobalDomain AppleLanguages -array "${LANGUAGES[@]}"
    defaults write NSGlobalDomain AppleLocale -string "$LOCALE"
    defaults write NSGlobalDomain AppleMeasurementUnits -string "$MEASUREMENT_UNITS"
    defaults write NSGlobalDomain AppleMetricUnits -bool true

    # Using systemsetup might give Error:-99, can be ignored (commands still work)
    # systemsetup manpage: https://ss64.com/osx/systemsetup.html

    # Set the time zone
    sudo defaults write /Library/Preferences/com.apple.timezone.auto Active -bool true
    sudo systemsetup -setusingnetworktime on || true

    # Enable 24-hour clock
    defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
}

# System
configure_system() {
    # Set system appearance to Dark mode
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

    # Restart automatically if the computer freezes (Error:-99 can be ignored)
    sudo systemsetup -setrestartfreeze on 2>/dev/null || true

    # Disable Sudden Motion Sensor
    sudo pmset -a sms 0

    # Automatically hide the macOS menu bar to make room for SketchyBar
    defaults write NSGlobalDomain _HIHideMenuBar -bool true

    # Menu bar: show battery percentage
    defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
    defaults write com.apple.menuextra.battery ShowPercent -bool true

    # Disable desktop widgets (macOS Sonoma and later)
    defaults write com.apple.WindowManager EnableDesktopWidgets -bool false
    defaults write com.apple.WindowManager StandardHideDesktopWidgets -bool true
    defaults write com.apple.WindowManager StageManagerHideDesktopWidgets -bool true
    defaults write com.apple.WindowManager StandardHideWidgets -bool true
    defaults write com.apple.WindowManager StageManagerHideWidgets -bool true

    # Remove all widgets from the Notification Center and Desktop by clearing user widget preferences
    defaults delete com.apple.notificationcenterui widgets 2>/dev/null || true

    # Disable opening and closing window animations
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

    # Increase window resize speed for Cocoa applications
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

    # Expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

    # Expand print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    # Save to disk (not to iCloud) by default
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

    # Automatically quit printer app once the print jobs complete
    defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

    # Disable the “Are you sure you want to open this application?” dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false

    # Disable Resume system-wide
    defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

    # Disable the crash reporter
    defaults write com.apple.CrashReporter DialogType -string "none"

    # Disable Notification Center and remove the menu bar icon
    launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null
}

# Catppuccin Macchiato Theme Tweaks
configure_theme() {
  # Enable macOS Dark Mode
  defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

  # Keep standard window controls; tint dark icons, widgets, and folders #B08EDA.
  defaults delete NSGlobalDomain AppleAquaColorVariant 2>/dev/null || true
  defaults write NSGlobalDomain AppleIconAppearanceTheme -string "TintedDark"
  defaults write NSGlobalDomain AppleIconAppearanceTintColor -string "Other"
  defaults write NSGlobalDomain AppleIconAppearanceCustomTintColor -string "0.690196 0.556863 0.854902 1.000000"

  # Use the Graphite accent preset and a darker #9679B9 text highlight.
  defaults write NSGlobalDomain AppleAccentColor -int -1
  defaults write NSGlobalDomain AppleHighlightColor -string "0.588235 0.474510 0.725490"

  # Reduce wallpaper tinting for more consistent dark window backgrounds
  defaults write NSGlobalDomain AppleReduceDesktopTinting -bool true
}

# Keyboard & Input
configure_keyboard() {
    # Disable Spotlight shortcut (Cmd+Space) and Finder search (Option+Cmd+Space) to free them for other apps
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>"
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1572864</integer></array><key>type</key><string>standard</string></dict></dict>"

    # Reload the hotkeys so the changes take effect immediately
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

    # Disable smart quotes and dashes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Enable full keyboard access for all controls
    # (e.g. enable Tab in modal dialogs)
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # Disable press-and-hold for keys in favor of key repeat
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

    # Set a blazingly fast keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 1
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Automatically illuminate built-in MacBook keyboard in low light
    defaults write com.apple.BezelServices kDim -bool true

    # Turn off keyboard illumination when computer is not used for 5 minutes
    defaults write com.apple.BezelServices kDimTime -int 300

    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Disable the Dictation shortcut to prevent the “Enable Dictation” prompt
    defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 0
}

# Trackpad, mouse, Bluetooth accessories
configure_trackpad_and_mouse() {
    # Trackpad: enable tap to click for this user and for the login screen
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    # Trackpad: map bottom right corner to right-click
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

    # Trackpad: swipe between pages with three fingers
    defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true
    defaults -currentHost write NSGlobalDomain com.apple.trackpad.threeFingerHorizSwipeGesture -int 1
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1

    # Increase sound quality for Bluetooth headphones/headsets
    defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

    # Invert scroll direction (natural scrolling off)
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
}

# Screen
configure_screen() {
    # Save screenshots to the ~/Screenshots folder
    mkdir -p "${SCREENSHOTS_FOLDER}"
    defaults write com.apple.screencapture location -string "${SCREENSHOTS_FOLDER}"

    # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
    defaults write com.apple.screencapture type -string "png"

    # Disable shadow in screenshots
    defaults write com.apple.screencapture disable-shadow -bool true

    # Enable subpixel font rendering on non-Apple LCDs
    defaults write NSGlobalDomain AppleFontSmoothing -int 2

    # Schedule Night Shift from 21:00 to 07:00 at maximum warmth
    nightlight schedule 21:00 07:00
    nightlight temp 100

    # Setting the schedule does not change the current on/off state.
    case "$(date +%H)" in
      21|22|23|00|01|02|03|04|05|06) nightlight on ;;
    esac

    # Set wallpaper
    if [[ -f "$WALLPAPER" ]]; then
      osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "'"$WALLPAPER"'"'

      # Also set the login window background to the same black image.
      sudo defaults write /Library/Preferences/com.apple.loginwindow DesktopPicture -string "$WALLPAPER"
    fi
}

# Finder
configure_finder() {
    # Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
    defaults write com.apple.finder QuitMenuItem -bool true

    # Finder: disable window animations and Get Info animations
    defaults write com.apple.finder DisableAllAnimations -bool true

    # Finder: show hidden files by default
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write NSGlobalDomain AppleShowAllFiles -bool true

    # Finder: show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Finder: show status bar
    defaults write com.apple.finder ShowStatusBar -bool true

    # Finder: show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Finder: allow text selection in Quick Look
    defaults write com.apple.finder QLEnableTextSelection -bool true

    # Display full POSIX path as Finder window title
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

    # Keep folders on top when sorting by name
    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    # When performing a search, search the current folder by default
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Disable disk image verification
    defaults write com.apple.frameworks.diskimages skip-verify -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

    # Always open everything in Finder's list view.
    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Disable the warning before emptying the Trash
    defaults write com.apple.finder WarnOnEmptyTrash -bool false

    # Expand the following File Info panes:
    # “General”, “Open with”, and “Sharing & Permissions”
    defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true
    # Open Downloads folder by default in new Finder windows
    defaults write com.apple.finder NewWindowTarget -string "PfLo"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"
}

# Dock
configure_dock() {
    # Show indicator lights for open applications in the Dock
    defaults write com.apple.dock show-process-indicators -bool true

    # Don’t animate opening applications from the Dock
    defaults write com.apple.dock launchanim -bool false

    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true

    # Make Dock icons of hidden applications translucent
    defaults write com.apple.dock showhidden -bool true

    # No bouncing icons
    defaults write com.apple.dock no-bouncing -bool true

    # Disable hot corners
    defaults write com.apple.dock wvous-tl-corner -int 0
    defaults write com.apple.dock wvous-tr-corner -int 0
    defaults write com.apple.dock wvous-bl-corner -int 0
    defaults write com.apple.dock wvous-br-corner -int 0

    # Don't show recently used applications in the Dock
    defaults write com.apple.Dock show-recents -bool false

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
    if command -v dockutil >/dev/null 2>&1; then
      dockutil --no-restart --remove all
    fi
}

# Mail
configure_mail() {
    # Display emails in threaded mode
    defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"

    # Disable send and reply animations in Mail.app
    defaults write com.apple.mail DisableReplyAnimations -bool true
    defaults write com.apple.mail DisableSendAnimations -bool true

    # Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
    defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

    # Disable inline attachments (just show the icons)
    defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

    # Disable automatic spell checking
    defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"

    # Disable sound for incoming mail
    defaults write com.apple.mail MailSound -string ""

    # Disable sound for other mail actions
    defaults write com.apple.mail PlayMailSounds -bool false

    # Mark all messages as read when opening a conversation
    defaults write com.apple.mail ConversationViewMarkAllAsRead -bool true

    # Disable includings results from trash in search
    defaults write com.apple.mail IndexTrash -bool false

    # Automatically check for new message (not every 5 minutes)
    defaults write com.apple.mail AutoFetch -bool true
    defaults write com.apple.mail PollTime -string "-1"

    # Show most recent message at the top in conversations
    defaults write com.apple.mail ConversationViewSortDescending -bool true
}

# Calendar
configure_calendar() {
    # Show week numbers (10.8 only)
    defaults write com.apple.iCal "Show Week Numbers" -bool true

    # Week starts on monday
    defaults write com.apple.iCal "first day of week" -int 1
}

# Terminal
configure_terminal() {
    # Only use UTF-8 in Terminal.app
    defaults write com.apple.terminal StringEncodings -array 4

    # Appearance
    defaults write com.apple.terminal "Default Window Settings" -string "Pro"
    defaults write com.apple.terminal "Startup Window Settings" -string "Pro"
    defaults write com.apple.Terminal ShowLineMarks -int 0
}

# Activity Monitor
configure_activity_monitor() {
    # Show the main window when launching Activity Monitor
    defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

    # Visualize CPU usage in the Activity Monitor Dock icon
    defaults write com.apple.ActivityMonitor IconType -int 5

    # Show all processes in Activity Monitor
    defaults write com.apple.ActivityMonitor ShowCategory -int 0

    # Sort Activity Monitor results by CPU usage
    defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    defaults write com.apple.ActivityMonitor SortDirection -int 0
}

# Software Updates
configure_software_updates() {
    # Enable the automatic update check
    defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

    # Check for software updates weekly (`dot update` includes software updates)
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -string 7

    # Download newly available updates in background
    defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true

    # Install System data files & security updates
    defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true

    # Turn on app auto-update
    defaults write com.apple.commerce AutoUpdate -bool true

    # Allow the App Store to reboot machine on macOS updates
    defaults write com.apple.commerce AutoUpdateRestartRequired -bool true
}

# Kill affected applications
restart_affected_applications() {
    for app in \
      "Activity Monitor" \
      "Address Book" \
      "Calendar" \
      "Contacts" \
      "ControlCenter" \
      "Dock" \
      "Finder" \
      "Mail" \
      "Safari" \
      "SystemUIServer" \
      "WindowManager" \
      "iCal"; do
      killall "$app" 2>/dev/null || true
    done
}

main() {
    osascript -e 'tell application "System Preferences" to quit'

    configure_computer_name
    configure_localization
    configure_system
    configure_theme
    configure_keyboard
    configure_trackpad_and_mouse
    configure_screen
    configure_finder
    configure_dock
    configure_mail
    configure_calendar
    configure_terminal
    configure_activity_monitor
    configure_software_updates
    restart_affected_applications
}

main "$@"
