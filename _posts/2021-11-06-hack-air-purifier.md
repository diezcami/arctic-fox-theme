---
layout: post
title: "Hacking my Air Purifier"
date: 2021-11-06
permalink: hack-air-purifier
tags: networking linux
---
<!-- ![1.png]({{site.url}}/assets/resources-hack-air-purifier/1.png) -->

## Man in the Middle

Proxying traffic from my android phone to my laptop, installing a CA cert to decrypt traffic.

Using a raspberry pi with a cheap WiFi antenna capable of being placed into "Monitor Mode".  

Pop it into the right mode with `airmon-ng start wlan1`.

### Airmon-ng

An `ifconfig` will show that the interface is now renamed to `wlan1mon`.

```
...
...
5: wlan1mon: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 9c:ef:d5:fa:34:8f brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.1/24 brd 192.168.1.255 scope global wlan1mon
```

#### Route setup

```bash
ifconfig wlan1mon up 192.168.1.1 netmask 255.255.255.0
route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
```

#### Provide internet access (optional)
```bash
iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface wlan1mon -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward
```

### Hostapd

$ `sudo hostapd hostapd.conf`

##### hostapd.conf
```
interface=wlan1mon
ssid=linksys5050
hw_mode=g
```

### Dnsmasq

$ `sudo dnsmasq -C dnsmasq.conf -d`

#### dnsmasq.conf
```
interface=wlan1mon
dhcp-range=192.168.1.2, 192.168.1.30, 255.255.255.0, 1h
dhcp-option=3, 192.168.1.1
dhcp-option=6, 192.168.1.1
server=1.1.1.1
log-queries
log-dhcp
listen-address=127.0.0.1
```

![1.png]({{site.url}}/assets/resources-hack-air-purifier/1.png)


### Resources

- [Some inspiration](https://xakcop.com/post/ctrl-air-purifier/)
- [Simple walkthough for getting hostapd up 'n running](https://blog.yezz.me/blog/How-To-Start-a-Fake-Access-Point)