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

Now create a group chat in the Telegram app and invited my new bot.  To retrieve that group chat's telegram "ID", you can invoke `getUpdates` to see all active chats your bot is in (which should just be the single one you added it to).  I use `jq` to parse out the appropriate value.

```bash
curl https://api.telegram.org/bot<YOUR_API_KEY_HERE>/getUpdates \
                                      | jq '.result[0].message.chat.id'

-4545454545
```

Without `jq` your response will look something like this:

```json
{
  "ok": true,
  "result": [
    {
      "update_id": 75757575,
      "message": {
        "message_id": 15,
        "from": {
          "is_bot": false,
          "first_name": "Josh",
        },
        "chat": {
          "id": -4545454545,
          "title": "My Cool Group",
          "type": "group",
          "all_members_are_administrators": true
        },
        "date": 1594511195,
        "new_chat_title": "My Cool Group"
      }
    }
  ]
}
```

Grab the relevant chat's "id" value, which represents the `CHAT_ID` below, and you'll  have all the pieces you need to invoke the bot! We interact with a simple GET request formatted like below.  Note the word "bot" preceding your API key.

```bash
curl https://api.telegram.org/bot<YOUR_API_KEY_HERE>/sendMessage?chat_id=<YOUR_CHAT_ID_HERE>&text=<YOUR_MSG>
```

The `<YOUR_MSG>` field can be anything url encoded. That's the message you'll receive in the telegram group chat from your bot.

## Script

Next, place this script anywhere on your router. For this example, i'm placing the script in `/root`, naming it `alert.sh`.

The script will check against a local cache of "seen" MAC addresses. If the grep fails on that file, we first make an API call to macvendors.com to get a rough idea of the device. _The first half of a (non-spoofed) MAC address indicates the device vendor!_  

The script then sends us a message via Telegram with some useful info, and logs this MAC address in its "seen" cache.

<script src="https://gist.github.com/joshspicer/e09c3158074cdd584c79e2bb5bd4e640.js"></script>

## Configure Your OpenWRT router

### Install hostapd-utils

Thanks to [this post](https://forum.openwrt.org/t/solved-assoc-disassoc-event-trigger/3341), I found a really elegant way to to only run my script on an association (connect/disconnect) from my access point.

On your router, install the package [hostapd-utils](https://www.systutorials.com/docs/linux/man/1-hostapd_cli/) and configure it to run our script on **each** interface you'd like it to watch. For example if you have a guest SSID on the 2.4GHz band and your "main" SSID on both bands, you'll have **three** interfaces you need to set up.  

```bash
opkg install hostapd-utils
hostapd_cli -a/root/alert.sh -B -iwlan0
hostapd_cli -a/root/alert.sh -B -iwlan0.1
hostapd_cli -a/root/alert.sh -B -iwlan1
```

The script should now run each time a device associates or dissociates with your AP, triggering a message if the MAC address had not been seen before.  While not resiliant to MAC spoofing, it is a quick and easy way to keep an eye on new devices joining your networks :) 