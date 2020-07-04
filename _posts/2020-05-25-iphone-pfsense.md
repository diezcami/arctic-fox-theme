---
layout: post
title: "Bridge iPhone Hotspot to LAN with Pfsense"
date: 2020-05-25
permalink: iphone-pfsense
tags: tips-tricks homelab networking
---

## Intro

Bridging your iPhone hotspot is useful for an array of reasons. Just move and not have internet from the local ISP yet? Want some redundancy in case the ISP fails? Maybe your phone's 4G is actually faster or more reliable? Whatever the reason, bridging your phone plan's internet connection is not too hard with open source router software Pfsense.

I use Pfsense as my LANs router. Pfsense is running on a proxmox server VM and is on the same subnet as a home router in "access point mode" to supply Wifi. **I assume in this guide you already have pfsense set up as your network's router/gateway**.

## Steps

The steps below were heavily inspired by [a 2016 pfsense forum post](https://forum.netgate.com/topic/106435/iphone-tether). Thank you to [daredevilbear](https://forum.netgate.com/user/daredevilbear) and [tff24](https://forum.netgate.com/user/tff24) for getting me started!

I am running Pfsense `2.4.5-RELEASE`, which already shipped with the freeBSD iPhone drivers `ipheth`. If you don't have that driver you'll need to follow the steps in the forum post above.

First, load in the drivers by executing:

`kldload if_ipheth`

Success if you load that in without an error message. You may now also be prompted to "trust this device" on your iPhone...do that.

Run `dmesg` to see if your iPhone is being detected. Take note of the value after `ugen`. In my case, the value is `1.2`.

![7.png]({{site.url}}/assets/resources-iphone-pfsense/7.png)

Above you also see the MAC address of my phone's hotspot getting picked up. Originally this DIDN'T happen for me, and first had to run:

`usbconfig -d 1.2 set_config 3`

where `1.2` is the value you observed above.

You will now hopefully see a new interface in the pfsense menu. In this example i'm assigning my hotspot as my WAN interface, but of course you could configure something in parallel to your regular WAN connection for redundancy.

![2.png]({{site.url}}/assets/resources-iphone-pfsense/2.png)

Two quirks i've noticed. First, I have to manually toggle the hotspot on/off on my iPhone to make the blue hotspot logo appear on the phone. Next, I need to toggle the WAN interface on/off in:

`Interfaces > WAN > Enable Interface.`

Checking pfsense, I now have an IP.

![8.png]({{site.url}}/assets/resources-iphone-pfsense/8.png)

If all goes well you should now be able to reach the internet!

![5.png]({{site.url}}/assets/resources-iphone-pfsense/5.png)

## Peristence

### Driver

Add `if_ipheth_load="YES"` to:

`/boot/defaults/loader.conf`

![4.png]({{site.url}}/assets/resources-iphone-pfsense/4.png)

### USB Config

Add the following `<earlyshellcmd>` to `/conf/config.xml`:

```xml
 <pfsense><version>17.0</version>
  <lastchange></lastchange>
  <system><optimization>normal</optimization>
    <hostname>pfSense</hostname>
    <domain>localdomain</domain>

    <dnsallowoverride></dnsallowoverride>
<earlyshellcmd>usbconfig -d 1.2 set_config 3</earlyshellcmd></system></pfsense>
```

Of course, changing `1.2` to whatever value you have.

Afterwards, remove the cache with `rm /tmp/config.cache`.

### Troubleshooting

Sometimes i've noticed pfsense having trouble acquiring an IP even though the interface appears to be up. For this I do the following.

1. Restart Pfsense (`Diagnostics > Reboot`) **with** iPhone plugged in
2. **As soon as** you are prompted to "trust" on your iPhone, do that and then quickly toggle hotspot off/on
3. You may be prompted to "trust" twice. Repeat step (2) if so
4. If "Setting up WAN" starts to hang during the boot up, start from step (1) and try again

Most of the time this works first try. You need to be quick with step 2, though!
