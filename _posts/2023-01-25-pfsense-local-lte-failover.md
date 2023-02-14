---
layout: post
title: "Local LTE Failover with Pfsense"
date: 2023-02-11
permalink: lte-failover-pfsense
---

> My Xfinity cable internet connection has been shockingly unreliable since I last moved.  That got me thinking about alternative options to keep my home connected.

## Introduction

The goal of an LTE fallback/failover is to provide a second WAN connection to your home network in case your primary connection goes down or the latency is too high.  "Failing over" means that all the devices on your LAN will have their internet requests transparently routed across the internet over the secondary WAN connection. It's useful for many reasons, including keeping "critical" devices (i.e security cameras or smart locks) up.  Software like Pfsense can offer a lot of flexibility in how to determine a "failover" scenario, which I will go into more detail below.

## Requirements

- Your home networking routing handled by [**Pfsense** VM](/homelab) or similar routing software that offers a "WAN failover" feature.

- A SIM card with an active data plan is required.

- A cellular modem of some sort - I bought the [Netgear LM1200](https://www.netgear.com/home/mobile-wifi/lte-modems/lm1200/), which is compatible with several US GSM carriers.  I've used it with SIM cards that piggyback on AT&T and T-Mobile networks (more on that later).


## Picking mobile carrier

I've been bouncing between a few different carriers trying to find a good fit.  I started out with a cheap $5/mo plan from [Tello](https://tello.com), which worked really well. They piggyback off T-Mobile's network, which is decent for where i'm located.

Lately i've been experimenting with companies offering IoT-oriented plans.  The SIMs from [Simbase](https://www.simbase.com/) are pretty compelling, as it's $0.01/day to keep the sim active, and $0.01/MB for data usage.  Since the goal of this project is to only have the failover "kick in" when my primary internet fails, having a low-commitment, low bandwidth plan is perfect.

## Modem Configuration

The modem configuration was very simple with the Netgear LM1200.  I just plugged in the SIM card and powered it on.  The modem automatically connected to the network and assigned itself an IP address. Plugging in an ethernet cable from the device to my computer, I was able to access the modem's web interface at the address printed.  With some carriers you'll need to configure the "APN" settings, but with Tello it was already set up (Simbase required APN settings, and also for me to enable "Data Roaming" mode).

Once you've confirmed you can access the internet via the mode, plug the ethernet cable into your Pfsense router.  You can then configure the modem as a second "WAN" interface in Pfsense.  I am able to use DHCP to get an IP address from my carrier.

## Pfsense Configuration

Create a new "Gateway Group" for your two WAN interfaces. Set your primary interface as Tier 1 and the your LTE interface as Tier 5.  This will ensure that the LTE modem is only used as a fallback.  I set "Trigger Level" to "Member down". 

![1.png]({{site.url}}/assets/resources-lte-failover-pfsense/1.png)  

For both interfaces you'll need to configure a Monitor IP for pfsense to use as a test for connectivity. My default was Comcast's gateway, but I changed my interfaces to monitor cloudflare's primary (1.1.1.1) and secondary (1.0.0.1) DNS servers.

![2.png]({{site.url}}/assets/resources-lte-failover-pfsense/2.png)

In order to keep my data plan bill low, I significantly decreased the frequency of the gateway monitor. This means that it takes longer to failover, but the result is just a tens of KB of daily data usage, compared to hundreds of MBs.  Here are my settings (which are working well), but I encourage you to tune them to your needs.

![3.png]({{site.url}}/assets/resources-lte-failover-pfsense/3.png)


You should now be able to unplug your primary WAN connection and see that your secondary connection is used as a fallback!
## Alerting

In Pfsense, under `System > Advanced > Notifications`, I configured Telegram alerts on system events (i.e a gateway going down).

That said, i've noticed that I don't get alerts consistently when the primary (Comcast)gateway goes down, only when it comes back up.  It appears to be either a bug in Pfsense or a timing issue with the gateway detection failover. 

## Tips

- This isn't a specific tip for LTE failover, but more generally i've found that most issues with my gateways can be fixed by going to `Status > Interfaces` and releasing and renewing the DHCP lease.  This is a good first step if you're having issues with either connection (and if you swap out SIM cards, for example, and need to refresh your DHCP lease that Pfsense is holding onto)
