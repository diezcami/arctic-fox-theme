---
layout: post
title: "Bluetooth Low Energy devices on HomeKit"
date: 2020-12-06
permalink: bluetooth-le-homekit
tags: linux hacking homelab
---

I recently bought a bluetooth thermometer/hydrometer [(Govee H5072)](https://www.amazon.com/dp/B07DWMJKP5/ref=cm_sw_em_r_mt_dp_MXoZFb6S7CWZD) for $15 on Amazon to use in my apartment.  After purchasing, I thought of several smart home automations that would be nice to have triggered based on the sensor's readings.  This device communicates via my phone with Bluetooth LE, and didn't offer any smarthome hooks in the app.  Govee also offers a **$60** WiFi version of this sensor that does work with the typical smart home providers.  

That got me curious - could I somehow pipe this sensor's Bluetooth data into my existing smart home infrastructure (saving me $45!).

To my surprise - lots of people must have aleady had this idea.  I ended up not needing to write any code - i'll walk you through the process here.

## Bluetooth LE

I have a cheap bluetooth dongle available to use on my [homelab](/homelab).  In proxmox I passed through that device to an Ubuntu VM.

I first identified the MAC address of the Govee hydrometer with `hcitool`.  

```bash
hciconfig hci0 down && hciconfig hci0 up  # I needed to do this 
hcitool lescan

# A4:C1:xx:xx:xx GVH5072_XXXX
# A4:C1:xx:xx:xx (unknown)
# 61:58:xx:xx:xx (unknown)
# F3:33:xx:xx:xx (unknown)
# F3:33:xx:xx:xx 846B522621FE33AEE9
# 5A:B8:xx:xx:xx (unknown)
# 32:89:xx:xx:xx (unknown)
# 5A:B8:xx:xx:xx (unknown)
# 5A:B8:xx:xx:xx (unknown)
# 61:58:xx:xx:xx (unknown)
```

The `GVH5072_XXXX` device matched the name of the device in my Govee app.

I was fully prepared to reverse engineer the communications. I read [this guide](https://thejeshgn.com/2020/08/05/reverse-engineering-a-bluetooth-low-energy-oximeter/) and [this other guide](https://www.instructables.com/Reverse-Engineering-Smart-Bluetooth-Low-Energy-Dev/) and used an old android device to generate a pcap file for analysis in wireshark.

Before moving forward though I looked a bit online, and to my surpise there was already a lot of work done.  Here is one python and node implementation by [Thrilleratplay](https://github.com/Thrilleratplay/GoveeWatcher), utilzing the awesome [bleson python module](https://github.com/TheCellule/python-bleson).

<script src="https://gist.github.com/joshspicer/0b7e4e411e4f7eb3d5d9493f8c6f5baf.js"></script>

The script observes the advertisement by the Govee device, which contains the snapshot information we're looking for.

```
$ python govee.py

GVH5072_XXXX 
Temperature 19C / 67F
Humidity: 45%
Battery:  100%

...
```

## Integration with HomeKit

I run [Homebridge](https://github.com/homebridge/homebridge) on a local machine to..uh.._bridge_ certain to make certain homekit _incompatible_ devices speak the Apple language. 

I found a plugin by [asednev](https://github.com/asednev/homebridge-plugin-govee) that worked great for my model of hydrometer.

There were some "gotchas" setting this up. Namely:

1. I had issue running this through a docker container (using hardware devices through containers is no easy feat). I ended up just spinning up homebridge on an existing Ubuntu server VM and passing through the dongle.
2. I had to follow the steps outlined for its [noble](https://github.com/abandonware/noble) - namely by running:

```bash
apt-get install bluetooth bluez libbluetooth-dev libudev-dev
setcap cap_net_raw+eip $(eval readlink -f $(which node))
```
on the host VM.

## It works!

Awesome - we now see our devices in the iOS Home app.

![map]({{site.url}}/assets/resources-bluetooth-le-homekit/homekit.jpeg)

With Siri automations you can trigger other things to happen around the home (namely interfacing with smart plugs, etc...).  I have other bluetooth devices around the house that I have yet to find premade solutions for.  Thanks to this investigation I feel confident in getting those hooked up to my homekit network as well.

