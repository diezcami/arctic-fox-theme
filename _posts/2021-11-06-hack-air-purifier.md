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


-----

## Man in the Middle with RaspAP

- [RaspAP](https://docs.raspap.com/)
- `ssh pi@raspberrypi.wo sudo tcpdump -i wlan1 -U -s0 -w - 'not port 22' | wireshark -k -i -`

### Frida 

[circumvent ssl pinning](https://joshspicer.com/ssl-pinning-android)

```
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: graph.facebook.com
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: graph.facebook.com
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: iocareapp.coway.com
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: iocareapp.coway.com
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: firebase-settings.crashlytics.com
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: iocareapp.coway.com
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: iocareapp.coway.com
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: maps.googleapis.com
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: d5zuhet69bkhw.cloudfront.net
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: maps.googleapis.com
[+] Bypassing TrustManagerImpl (Android > 7) checkTrustedRecursive check: d5zuhet69bkhw.cloudfront.net
```

Get list of packages: `adb shell pm list packages -3 -f`


#### mitmproxy

https://www.dinofizzotti.com/blog/2019-01-09-running-a-man-in-the-middle-proxy-on-a-raspberry-pi-3/
https://hackaday.io/project/10338/instructions


With RaspAP setup, all we need to get it to play nice with mitmproxy is adding two prerouting rules for HTTP and HTTPS traffic.

```
sudo iptables -t nat -A PREROUTING -i wlan1 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8080
sudo iptables -t nat -A PREROUTING -i wlan1 -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 8080
```

Then run mitmproxy transparently.

`mitmproxy --mode transparent`

#### Access Tokens

First Arp

![1.png]({{site.url}}/assets/resources-hack-air-purifier/arp.png)

 Able to read app -> service tokens

 ```
 {
  "body": {
    "unreadYN": "N"
  },
  "header": {
    "accessToken": "<...some jwt...>",
    "error_code": "",
    "error_text": "",
    "info_text": "",
    "login_session_id": "",
    "message_version": "",
    "refreshToken": "<...some jwt ...>",
    "result": true,
    "trcode": "CWIG1004"
  }
}
 ```

 There is some verification of some sort going on between app and sergvice`https://iocareapp.coway.com/bizmob.iocare/CWIZ0010.json`

Req.
```
{"header":{"login_session_id":"","trcode":"CWIZ0010","message_version":"1.0.1","result":true,"error_code":"","error_text":"","info_text":"","is_cryption":false},"body":{"appbuildversion":62,"appminorversion":3,"appmajorversion":2,"verificationCode":"<..some code...>","appKey":"<... some key ...>","langCd":"en"}}
```

Res.
```
{
  "body": {
    "result": "<..some result..>"
  },
  "header": {
    "accessToken": null,
    "error_code": "",
    "error_text": "",
    "info_text": "",
    "login_session_id": "",
    "message_version": "1.0.1",
    "refreshToken": null,
    "result": true,
    "trcode": "CWIZ0010"
  }
}

```

This stuff is cool, but it's already been reversed and utilized in the homebridge extension.  I'm more interested in cutting out the coway AWS service entirely and controlling the air purifier without relying on the provided service.

#### Analyzing Wireshark + Spoofing DNS


Immediately once the air purifier device is provided Wifi info, it does a DNS request to find the server it should make its handshake with.

Spoof Initial DNS: https://github.com/robert/how-to-build-a-tcp-proxy
```
7094	1093.268754	10.77.0.219	1.1.1.1	DNS	80	Standard query 0x0000 A airusf5o.coway.co.kr
```

```
7095	1093.690873	1.1.1.1	10.77.0.219	DNS	184	Standard query response 0x0000 A airusf5o.coway.co.kr CNAME elb-plicegw-01-1801026241.ap-northeast-2.elb.amazonaws.com A 3.36.253.214 A 52.79.160.61
```

Unplug/Replug in causes DNS request and handshake to reset (see Bear screenshot). Using `fake_dns_server.py` I can trick the device into handshake with a service I control (Is that interesting though?).


![dns-normal.png]({{site.url}}/assets/resources-hack-air-purifier/dns-normal.png)

![dns-spoof-terminal.png]({{site.url}}/assets/resources-hack-air-purifier/dns-spoof-terminal.png)

![dns-spoof.png]({{site.url}}/assets/resources-hack-air-purifier/dns-spoof.png)

#### Emulate real service

The next step after DNS seems to be to attempt a TLS handshake with the service over TCP over port 9090.

![syn9090.png]({{site.url}}/assets/resources-hack-air-purifier/syn9090.png)


```
nc -l localhost 12345
```

```
./ghostunnel server \
    --listen 0.0.0.0:9090 \
    --target localhost:12345 \
    --keystore test-keys/server-keystore.p12 \
    --cacert test-keys/cacert.pem \
    --allow-all
```

```
[20027] 2022/01/17 21:55:03.899372 starting ghostunnel in server mode
[20027] 2022/01/17 21:55:03.900047 using keystore file on disk as certificate source
[20027] 2022/01/17 21:55:03.929614 using target address localhost:12345
[20027] 2022/01/17 21:55:03.929871 listening for connections on 0.0.0.0:9090
[20027] 2022/01/17 21:55:55.228107 error on TLS handshake from 10.77.0.219:58860: tls: client offered only unsupported versions: [301]
```
Maybe need to allow older TLS version on host's openSSL install: https://tk-sls.de/wp/5200 and https://github.com/SoftEtherVPN/SoftEtherVPN/issues/1358?



-----

### Resources

- [Some inspiration](https://xakcop.com/post/ctrl-air-purifier/)
- [Simple walkthough for getting hostapd up 'n running](https://blog.yezz.me/blog/How-To-Start-a-Fake-Access-Point)

- https://robertheaton.com/2019/11/21/how-to-man-in-the-middle-your-iot-devices/