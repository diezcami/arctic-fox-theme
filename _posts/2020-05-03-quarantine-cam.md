---
layout: post
title: "Repurpose an old iPhone as a (Teams/Slack/Zoom) Mac Webcam"
date: 2020-05-03
permalink: quarantine-cam
tags: macOS
---

Like many people these days in the quarantine/COVID-19/social distancing world, i've been living my life through video calling apps like Microsoft Teams, Slack, and Zoom. When working at my monitor, it is cumbersome to prop my laptop open next to my external keyboard and mouse setup. In addition, the video quality of laptop webcams STILL suck in 2020. I looked into buying a cheap USB webcam, but these days finding one online is either very difficult, or incredibly price-gouging.

That got me thinking - what do I have laying around? I've got several old iPhones with fantastic cameras. Why not repurpose those?

I'm definitely not the first to think of this, but yet I haven't been able to find any definitive guide for newer MacOS editions (ie Catalina with Hardened Runtime). Below are my ramblings (cleaned up work notes) of how I got it working with Microsoft Teams, Slack, and Zoom on my Macbook / OSX.

## WARNING

You have the option to deliberately tamper with security features by reading on! We will also be running open source code not written by me. I don't take any responsibility for anything that follows from this post. For all the reasons not to do this, check [Objective See's blog post regarding Zoom](https://objective-see.com/blog/blog_0x56.html) (now slightly outdated as Zoom has been actively mitigating these attacks).

Please only continue if you understand the risk and know what you're doing! This post is mainly for my own research and curiosity.

This post is also not complete or tested in various environments. I assume you have standard xcode developer tools already installed `xcode-select install`/`brew`/etc. Think of this less as a complete guide, and more as my work notes.

## The Problem

I tried using existing tools like [Cam Twist](http://camtwiststudio.com/download/) and [obs-mac-virtualcam](https://github.com/johnboiles/obs-mac-virtualcam) , but didn't have any luck. Upon some research I discovered that newer versions of macOS enable [library validation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_cs_disable-library-validation) by default. Apple explains what this is best:

> Typically, the Hardened Runtime’s library validation prevents an app from loading frameworks, plug-ins, or libraries unless they’re either signed by Apple or **signed with the same team ID as the app**. The macOS dynamic linker (dyld) provides a detailed error message when this happens. Use the Disable Library Validation Entitlement to circumvent this restriction.

Basically, any app that goes through the notarization and gatekeeper process now, and which doesn't provide this opt-out entitlement, will deny any Framework with another team ID's signature being linked in.

At this time none of the big chat platforms support virtual cameras (what you'll our final solution, OBS, uses). Because of this, we need to be able to load in our own code _somehow_.

This is why a lot of pre-existing solutions have started failing. It's also why [just a few weeks ago Zoom stopped working with existing solutions](https://github.com/johnboiles/obs-mac-virtualcam/issues/4#issuecomment-611910527). I'm happy companies are paying attention (being forced by Apple) to enforce stricter security policies - having this enabled by default mitigates a whole class of malicious attacks. That said, it breaks a lot of existing community tooling.

## Considerations

### Developer Account

Note, I will be re-signing the binaries we unwrap with my personal Apple developer account (the one that costs \$99/yr). I haven't fully tested it without a developer account, but you can try replacing any of the `--sign` parameters in `codesign` with `-`.

For example if I do
`sudo codesign --sign <MY_DEV_ID>`

You can try
`sudo codesign --sign -`

### Versions

I've tested this with an iPhone XS on `13.5 (beta)` and an iPhone 6s on iOS `11.2.5`.

Note that I **couldn't** get OBS Studio to work with an old, jailbroken iPhone on `9.3.3`. Not sure why 🤷🏽‍♂️.

I am running macOS `10.15.4` Catalina. You may only need to complete the first part in Mojave and older.

I am running the latest release version (as of May 3rd, 2020) of Teams/Zoom/Slack.

- Microsoft Teams `1.3.00.4410-E`
- Zoom Version: `5.0.1 (23508.0430)`
- Slack: `Version 4.5.0 030422a-s@1588375643 (Production)`

Make sure to download these apps from their respective websites - NOT the Mac App Store. If you enter "wiggle mode" in Launchpad and your app has a little "x", it is from the App Store.

## Steps

### Download OBS-Studio and OBS-Mac-Virtualcam

[OBS Studio](https://obsproject.com/) is open source software for video recording and live streaming. This software serves as the base for our solution.

We then use [obs-mac-virtualcam](https://github.com/johnboiles/obs-mac-virtualcam) to create a "virtual webcam" outputting a video feed of the screen from our iPhone.

I followed their steps exactly in the [README's build section](https://github.com/johnboiles/obs-mac-virtualcam#building), to build both OBS-Studio and OBS-Mac-VirtualCam from source.

I decided to sign the plugin with my developer account as mentioned in [this issue](https://github.com/johnboiles/obs-mac-virtualcam/issues/4#issuecomment-609542482). This is only required if you'll be signing each app and framework along the chain to maintain the macOS security entitlements.

_Note: For the sake of this guide i'll assume not everyone has a developer account, and will continue on with the more unsafe, but simpler approach._

Once you run `./obs`, move the program into focus and go to `Tools -> Start Virtual Camera`. Inside the GUI you'll also need to select your (plugged in & trusted) iPhone from `source` (at the bottom) -> `Video Capture Devices`. You should now see a live output of your iPhone screen inside the OBS app. _If you don't, stop here and fix that first_.

Since OBS is just streaming your iPhone's screen, you'll want to open a camera app. I saw another user suggest [Instagram's Hyperlapse](https://apps.apple.com/us/app/hyperlapse-from-instagram/id740146917) app. It's a good candidate because of it's minimal UI (you'll want to use OBS studio to crop out the UI elements), and it also is a timelapse app, so it doesn't sleep your device.

### Chat App Setup

In an ideal world - we'd be done! However opening up Teams/Slack/Zoom, you'll see that your OBS device isn't available as a webcam source. This is because the operating system is not allowing any libraries not signed by the same App ID.

#### Teams

Lets start with an easy one. Teams just worked...no library validation errors. I was a bit surprised.

![teams.png]({{site.url}}/assets/resources-quarantine-cam/teams.png)

#### Zoom

For zoom I am using part of [hkatz's](https://hkatz.dev/) mitgation for [this obs-mac-virtualcam issue](https://github.com/johnboiles/obs-mac-virtualcam/issues/4#issuecomment-612568927). Huge thanks to him for the insightful issue replies!

First make sure you have `xml2` installed via `brew install xml2`.

Below, replace `<YOUR-DEV-ID>` with either your 40 character hex identifier, or simply `-` for none.

Check all the code signing identities available on your Mac with `security find-identity -v -p codesigning`. This is assuming you've done some MacOS Xcode development on your machine, and are signed into your developer account in Xcode. You can head to the [Apple Developer Certificate Center](https://developer.apple.com/account/resources/certificates/list) to generate new Developer IDs.

```
APPLICATION=/Applications/zoom.us.app \
&& codesign -d --entitlements :- $APPLICATION | \
{ xml2; echo "/plist/dict/key=com.apple.security.cs.disable-library-validation"; echo "/plist/dict/true"; } | \
2xml > entitlements.xml \
&& sudo codesign \
--sign <YOUR-DEV-ID> $APPLICATION \
--force \
--preserve-metadata=identifier,resource-rules \
--entitlements=entitlements.xml \
&& rm entitlements.xml
```

Let's break that down.

1. Set `$APPLICATION` to Zoom in our app folder.
2. Echo the app's entitlements and ADD the `disable-library-validation` key.
3. Resign the application with the updated entitlements, preserving existing identifers, resource-rules. I omitted `flags` from this list.

_Note 1: If you're adapting this guide slightly for use with another app and you see "File cannot be found", check if the app or framework has a space in the name. If so, then check out [this issue](https://github.com/CocoaPods/CocoaPods/issues/6153)._

_Note 2: To maintain the security benefits of lib validation, keep `library-validation` enabled and simply resign the app with your developer ID. Then sign any third-party software you'll want to use within Zoom with the same ID. This way, we satisfy library validation by only linking libraries with a shared App ID._

A more drastic solution that _may_ work is simply removing the signature altogether `codesign -d --remove-signature $APPLICATION`. The prior solution preserves other security considerations and should be preferred.

Note that if you need to also resign embedded libraries, such as `Frameworks`, you can also pass the `--deep` parameter to **both** codesign sub-commands above. This is the explanation of `--deep` from the `codesign` `man` page.

> When signing a bundle, specifies that nested code content such as helpers, frameworks, and plug-ins, should be recursively signed in turn. Beware that all signing options you specify will apply, in turn, to such nested content. When verifying a bundle, specifies that any nested code content will be recursively verified as to its full content...

It's very important to re-sign all of the Frameworks (if any), because if not the unmodified code (with library validation) may refuse to load in. For Zoom, this didn't seem to be the case.

To validate your handy-work you can run `codesign -dv <APP>`.

```bash
➜ codesign -dv /Applications/zoom.us.app

Executable=/Applications/zoom.us.app/Contents/MacOS/zoom.us
Identifier=us.zoom.xos
Format=app bundle with Mach-O thin (x86_64)
CodeDirectory v=20200 size=619 flags=0x0(none) hashes=12+5 location=embedded
Signature size=9062
Timestamp=May 3, 2020 at 10:30:05 AM
Info.plist entries=30
TeamIdentifier=<YOUR TEAM ID>
Sealed Resources version=2 rules=13 files=79
Internal requirements count=1 size=172
```

```bash
➜ codesign -d --entitlements :- /Applications/zoom.us.app

Executable=/Applications/zoom.us.app/Contents/MacOS/zoom.us
<plist><dict><key>com.apple.security.cs.disable-library-validation</key><true/></dict></plist>
```

The app is now signed with your developer account, with the entitlements of your choosing.

Security software will detect that your app's signature has changed and should hopefully alert you.

![1.png]({{site.url}}/assets/resources-quarantine-cam/1.png)

If all goes well, you should now be able to select your OBS Cam from video input devices.

![zoom.png]({{site.url}}/assets/resources-quarantine-cam/zoom.png)

#### Slack

Slack also did not work "out of the box". I tried to follow the same process as above but got hit with this.

```
Dyld Error Message:
Library not loaded: @rpath/Electron Framework.framework/Electron Framework
Referenced from: /Applications/Slack.app/Contents/MacOS/Slack
Reason: no suitable image found. Did find:
/Applications/Slack.app/Contents/MacOS/../Frameworks/Electron Framework.framework/Electron Framework: code signature in (/Applications/Slack.app/Contents/MacOS/../Frameworks/Electron Framework.framework/Electron Framework) not valid for use in process using Library Validation: mapping process and mapped file (non-platform) have different Team IDs
/Applications/Slack.app/Contents/MacOS/../Frameworks/Electron Framework.framework/Electron Framework: stat() failed with errno=1
```

Aha, looks like library validation at work! I thought just adding `--deep` to resign all of the Frameworks Slack links against would do the trick. That "worked", but then caused a much worse crash on launching Slack.

Slack is an Electron app, and conveniently there exists a tool from Electron themselves titled [electron-osx-sign](https://github.com/electron/electron-osx-sign). You can pull it easily with npm: `npm install -g electron-osx-sign`.

I suspect there are some better settings, but these worked for me a proof of concept.

```bash
➜ electron-osx-sign /Applications/Slack.app \
--type=development \
--entitlements="/Users/josh/entitlements.xml" \
--gatekeeper-assess=false

Application signed: /Applications/Slack.app
```

_Note: Again, you can avoid passing this entitlement by ensuring all linked software is signed with the same Application ID and adhering to the library validation rules._

If you do decide to remove library validation, here is the entitlement xml I used in testing `/Users/josh/entitlements.xml`:

```xml
Executable=/Applications/Slack.app/Contents/MacOS/Slack
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.cs.disable-library-validation</key>
	<true/>
</dict>
</plist>
```

![slack.png]({{site.url}}/assets/resources-quarantine-cam/slack.png)
