---
layout: post
title: "Keep your Home Number While Abroad (iCloud Hack)"
date: 2018-09-18
permalink: dual-sim-hack
favorite: "true"
---

I recently moved to the UK for my semester abroad. While still at home, I knew I wanted to pick up a local
SIM card when arriving in Europe. Local SIMs in the UK are pretty cheap, will let me call locally for cheap, and let me avoid
paying AT&T crazy fees. The more I thought about it, however, the more I wondered how feasible that idea was.
<br><br>
My normal (American) phone number is also tied to tons of online services for two-factor authentication.
I knew that if I simply swapped the SIMs, i'd of course stop getting text messages from my American number, and therefore lose
access to all the services that don't let me use a dedicated authenticator app (which is still too many services!).
<br><br>
My solution was a bit unconventional, but actually ended up letting me receive iMessage and SMS texts while abroad seamlessly alongside
my UK phone number. Calls, unfortunately, are not forwarded. This trick works because Apple lets you have one phone number per iPhone on your
account, so multiple per iCloud account. This is coupled with the continuity features of iOS and the text message forwarding feature.
<br><br>
**My solution was to run an "iPhone server" back on my home network with my home SIM inside.
Since my old iPhone is jailbroken, I also run a VNC server onboard that allows me to remotely manage the device from overseas.**
<br><br>
Since then Apple had announced their new iPhone with dual-SIM support (a little late for me, Apple!). I also know tons of Android devices have
had dual SIM support for ages, but i'm an Apple ecosystem guy.

## Basic Steps

1.  Keep a spare iPhone (preferably jailbroken) in your home country
2.  Add your home SIM into that spare phone
3.  Enable "Text Message Forwarding" on your spare iPhone
4.  Sign into the same iCloud account on all your devices
5.  On your daily iphone, enable the additional phone number in your Message settings
    <p></p>
    ![iphone-photo]({{site.url}}/assets/resources-sim-hack/iphone-photo.jpeg)
    <p></p>

## Bonus Steps (for administration)

1.  Figure out a way to securely VPN into your home's network. I run an OpenVPN server on a raspberry pi acting as my gateway onto the LAN.
2.  Install **Veency** (VNC server) from Cydia on your jailbroken phone and enable.
3.  Install a VNC client on the device you'll have abroad.
4.  Connect and manage your device from across the world!
    <p></p>
    ![vnc]({{site.url}}/assets/resources-sim-hack/VNC.png)
