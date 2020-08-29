---
layout: post
title: "My MacOS Tips & Tweaks"
date: 2020-04-19
permalink: macos-tweaks
tags: macOS tips-tricks
---

> **Updated** favorite apps on July 2nd 2020

## Show Hidden Folders in Finder

MacOS Sierra introduced a quick keyboard shortcut to show/hide hidden (dot) files.  

When in finder just type:

```
 CMD + SHIFT + .
```

## Enable Full Word Backspace in Terminal

I use the `Option + delete` keyboard combo to delete full words all throughout MacOS.  By default Terminal doesn't honor the full word backspace.  Enabling it is really simple:

1. Go to `Terminal > Preferences > Profiles > Keyboard`
2. Check "Use option key as meta key"

## Sudo with Touch ID

Typing your sudo password is a lot of work! Utilize the touchID Pluggable Authentication Module (PAM) to run those commands quickly!

```bash
cd /etc/pam.d
sudo chmod +w sudo
```

Add a new first entry to include the PAM module `pam_tid.so` (like so):

```
# sudo: auth account password session
auth       sufficient     pam_tid.so
auth       sufficient     pam_smartcard.so
auth       required       pam_opendirectory.so
account    required       pam_permit.so
password   required       pam_deny.so
session    required       pam_permit.so
```

If you're using iTerm, you'll need to disable this option in:

`Preferences => Advanced => Allow sessions to survive logging out and back in`

![1]({{site.url}}/assets/resources-macos-tweaks/1.png)

Restart your terminal and run a `sudo` command!

![2]({{site.url}}/assets/resources-macos-tweaks/2.png)

## \*Actually\* Disable App Relaunch On Restart

Apps relaunching on a reboot drives me crazy. I don't want this "feature" _ever_, not on a crash, not when rebooting from a script, and definitely not when I reboot myself. I found this tip on [Stackoverflow](https://apple.stackexchange.com/questions/129327/avoiding-all-apps-reopening-when-os-x-crashes) that restricts the permission on the file used to restore.

- Mark file as owned by root (or else MacOS will just regenerate the file)

```bash
sudo chown root ~/Library/Preferences/ByHost/com.apple.loginwindow*
```

- Steal all permissions

```bash
sudo chmod 000 ~/Library/Preferences/ByHost/com.apple.loginwindow*
```

To restore, just `rm` that file so macOS can regenerate it.

## Disable Bluetooth auto-connect

I have Sony WH-1000XM3 wireless headphones that I love, EXCEPT for the fact that they can only pair with one device.  The headphones often auto-connect to my Macbook, even if it's closed and sleeping. If i'm trying to pair the headphone to my phone, this can get very annoying as the only way to unpair is to login to my Macbook and disconnect from there.

I disable Bluetooth auto-connecting across the board with this terminal command:

```bash
sudo defaults write /Library/Preferences/com.apple.Bluetooth.plist DontPageAudioDevices 1
```

## First Hour Installs

Below is a list of the software (off the top of my head) that I immediately install on a fresh Mac.

### Favorite Utilites

- Itsycal
- SpotStatus
- Brew
- OhMyZsh
- CopyClip
- ~Amethyst~ Magnet
- TunnelBlick
- BetterTouchTool
- Arq
- GnuPG
- jq
- Gifski
- pcregrep (grep across lines)

### Favorite Apps

- Proxyman
- DaisyDisk
- Bear
- qBitTorrent
- Burp Suite Community
- VS Code
- Little Snitch
- Hex Fiend

## Dot Files

I back up [my dotfiles](https://github.com/joshspicer/dotfiles) and configuration settings. Notably some vim, vscode keybindings, and git settings. These are easy to restore with a symlink.
