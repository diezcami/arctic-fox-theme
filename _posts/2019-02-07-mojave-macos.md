---
layout: post
title: "AppleScript + Swift + Mojave"
date: 2019-02-07
redirect_from:
  - /SpotStatus/
  - /spotstatus/
permalink: applescript-mojave
favorite: "true"

---

I recently discovered AppleScript and I _love_ it. Unfortunately i'm **several** years late, and with Mojave's latest security additions, AppleScript is more restricted then ever.

For two pieces of technology both designed by Apple, it is surprising hard (and not well-documented) on how to get AppleScript working correct in a Mac app. I’m going to quickly document what I noticed working with AppleScript in Swift 4 on OSX Mojave.

### SpotStatus

For a full working example of everything in this post, check out [SpotStatus](https://github.com/joshspicer/SpotStatus) - my Now Playing Menu Bar Utility for MacOS Mojave.

![5]({{site.url}}//assets/resources-mojave/5.png)

## AppleScript Intro

First, a bit about the AppleScript - the hidden gem of MacOS automation. I never realized how many apps have native support for pretty deep automation. Even cooler, the built in “Script Editor” has a built in dictionary that lists the entire set of commands for each app.

![1]({{site.url}}//assets/resources-mojave/1.png)

Here’s Spotify’s. This is what I leverage to get the song information.

![2]({{site.url}}//assets/resources-mojave/2.png)

## Sandboxing

First things first, we need to disable sandboxing.

I kept on getting this error when I started out. I was a bit confused since Spotify was indeed running.

```
*{*
*NSAppleScriptErrorAppName = Spotify;*
*NSAppleScriptErrorBriefMessage = “Application isn\U2019t running.”;*
*NSAppleScriptErrorMessage = “Spotify got an error: Application isn\U2019t running.”;*
*NSAppleScriptErrorNumber = “-600”;*
*NSAppleScriptErrorRange = “NSRange: {38, 4}”;*
*}*
```

Not too helpful an error. To fix this, you’ll need to disable App Sandboxing.

![3]({{site.url}}//assets/resources-mojave/3.png)

I think this may mean you aren’t able to submit to the App Store, but I’m not positive. I’m mainly developing this for myself and for others to play around with, so I don’t care too much.

## Event Usage

The next error seemed more useful, but was actually harder to debug.

```
*{*
*NSAppleScriptErrorAppName = Spotify;*
*NSAppleScriptErrorBriefMessage = "Not authorized to send Apple events to Spotify.";*
*NSAppleScriptErrorMessage = "Not authorized to send Apple events to Spotify.";*
*NSAppleScriptErrorNumber = "-1743";*
*NSAppleScriptErrorRange = "NSRange: {99, 7}";*
*}*
```

The simple (in hindsight) fix is to add the follow key to your Info.plist.

```
    <key>NSAppleEventsUsageDescription</key>
    <string>...this is why I need permission...</string>
```

Now on first launch you’ll get a popup asking for permission for the app to communicate with whatever program your script is querying. Note that this is a Mojave thing, and I don’t think the popups happen on older OSX versions.

If you accidentally decline the popup, or you want to revoke access later, you can do so in the “automation” section here.

![4]({{site.url}}//assets/resources-mojave/4.png)

## NSAppleScript

The configuration is out of the way - lets use some AppleScript! I found a lot of _really bad_ guides on the internet of how to do this. The NSAppleScript documentation is a little confusing, but actually really simple once you wrap your head around it. Don't forget to `import Foundation` at the top of your file!

Here is the AppleScript, stored as a string at the top of my Swift file. You can craft this by opening up the Script Editor we opened up earlier.

```swift

import Foundation

let currentTrackScript = """
if application "Spotify" is running then
    tell application "Spotify"
        if player state is playing then
            return name of current track
        else
            return ""
    end if
    end tell
else
    return ""
end if
"""
```

Here I run the above script using the NSAppleScript API. The output can be accessed as a string via `out.stringValue`.

```swift

var out: NSAppleEventDescriptor?

if let scriptObject = NSAppleScript(source: currentTrackScript) {
    var errorDict: NSDictionary? = nil
    out = scriptObject.executeAndReturnError(&errorDict)
    songName = out?.stringValue ?? ""

    if let error = errorDict {
        print(error)
    }
}
```
