---
layout: post
title: "Detect New Devices on your Network (OpenWRT + Telegram API)"
date: 2020-07-11
permalink: openwrt-alert
tags: networking linux
---

One feature I really liked from my old Xfinity router were the push notifications it sent when new devices first joined my wireless network.  In this post we're recreating that functionality on an OpenWRT access point/router with the Telegram API.

![1.png]({{site.url}}/assets/resources-openwrt-alert/1.png)


## Create a Telegram bot

Creating a bot is super simple.  First, start a converation with [BotFather](https://t.me/BotFather).  He will guide you through creating a new bot!

```
Josh:       /newbot
BotFather:  Pick a name.
Josh:       My Bot
BotFather:  Pick a nickname.
Josh:       myBot
BotFather:  
            Done! Congratulations on your new bot, t.me/myBot.
            Use this token to access the HTTP API:
            <YOUR_API_KEY_HERE>
            Keep your token secure, it can be used to control your bot.
```

Now create a group chat in the Telegram app and invited my new bot.  To retrieve that group chat's telegram "ID", you can invoke `getUpdates` to see all active chats your bot is in (which should just be the single one you added it to).  I use `jq` to parse the returned JSON.

_NOTE: if this is a group chat you'll need to do some extra steps - see this [StackOverflow post](https://stackoverflow.com/questions/38565952/how-to-receive-messages-in-group-chats-using-telegram-bot-api)_

> [UPDATE] An even easier way to get the chat id is by signing into the web version of telegram and looking for the chat id query parameter!

Replace `$APIKEY` with your api key.

```bash
curl https://api.telegram.org/bot$APIKEY/getUpdates| jq
```

The response will look someting like this.

```json
{
  "ok": true,
  "result": [
    {
      "update_id": 999999999,
      "message": {
        "message_id": 1,
        "from": {
          "id": XXXXXXXXXXX,
          "is_bot": false,
          "first_name": "Josh",
          "language_code": "en"
        },
        "chat": {
          "id": XXXXXXXXXXX,
          "first_name": "Josh",
          "type": "private"
          ...
          ...
          ...
```

You'll want to take note of the value you see in place of `XXXXXXXXXX`, which represents the `$CHATID` below.

We then make a simple GET request formatted like below.  Note the word "bot" preceding your API key.

Replace `$APIKEY`, `$CHATID`, and `$MSG` appropriately.

```bash
curl https://api.telegram.org/bot$APIKEY/sendMessage?chat_id=$CHATID&text=$MSG
```

The `$MSG` field can be anything url encoded. That's the message you'll receive in the telegram group chat from your bot.

## Configure Your OpenWRT router

### Install hostapd-utils

Thanks to [this post](https://forum.openwrt.org/t/solved-assoc-disassoc-event-trigger/3341), I found a really elegant way to to only run my script on an association (connect/disconnect) from my access point.

On your router, install the package [hostapd-utils](https://www.systutorials.com/docs/linux/man/1-hostapd_cli/) and configure it to run our script on **each** interface you'd like it to watch. For example if you have a guest SSID on the 2.4GHz band and your "main" SSID on both bands, you'll have **three** interfaces you need to set up. Make sure to install `hostapd-utils`.  The rest we will be wrapping into a script to run on each boot.

```bash
opkg install hostapd-utils

hostapd_cli -a/root/alert.sh -B -iwlan0
hostapd_cli -a/root/alert.sh -B -iwlan0-1
hostapd_cli -a/root/alert.sh -B -iwlan1
```

## Scripts

I have three scripts in total. **(1)** A script I run on each boot, **(2)** a script run on an association event to my access point, and  **(3)** a script to manually run through all active associations.  These scripts can be anywhere on your router. For this example, i'm placing the script in `/root`, naming them `event_alert.sh` and `boot_alert.sh`, and `manual_alert.sh`.

### Boot Script

The boot script is run once on boot. We're going to invoke our boot script from `/etc/rc.local`.

#### /etc/rc.local
```sh
/root/boot_alert.sh
exit 0
```

This script alerts us that our router has restarted, and also sets up the connection events to listen for. Due to a race condition, I just simply `sleep` for 20 seconds before setting up the events.  I then run `manual_alert.sh` to catch any associations i've missed in that 20 seconds.

<script src="https://gist.github.com/joshspicer/e09c3158074cdd584c79e2bb5bd4e640.js?file=boot_alert.sh"></script>

### Manual Script


This script simply loops through and fetches every MAC address currently associated with the AP. Then it checks against a local cache of "seen" MAC addresses. If the grep fails on that file, we first make an API call to macvendors.com to get a rough idea of the device. _The first half of a (non-spoofed) MAC address indicates the device vendor!_  It will then send a Telegram message to my phone with the device's information.

<script src="https://gist.github.com/joshspicer/e09c3158074cdd584c79e2bb5bd4e640.js?file=manual_alert.sh"></script>

### Event Script

This script will run when a device associates (or dissociates) with the access point.  It is automatically called by `hostapd` through the setup we did in the boot script above.  If it finds a match, it works just like the script above, logging the MAC in the shared cache and sending a Telegram message.

<script src="https://gist.github.com/joshspicer/e09c3158074cdd584c79e2bb5bd4e640.js?file=event_alert.sh"></script>


The script will now run each time a device starts talking with your AP.  While not resiliant to MAC spoofing, it is a quick and easy way to keep an eye on new devices joining your networks :) 

----

A simple, barebones template to script telegram message can be seen below. 

```bash
#!/bin/bash

# Sends a telegram message to your bot!

MESSAGE="$1"

API_TOKEN=''
CHAT_ID=''

TELEGRAM="https://api.telegram.org/bot$API_TOKEN/sendMessage?chat_id=$CHAT_ID&text="         
                                                                                                                                  
/usr/bin/curl "$TELEGRAM$MESSAGE" 
```

Usage: `./telegram.sh "Hello World!"`
