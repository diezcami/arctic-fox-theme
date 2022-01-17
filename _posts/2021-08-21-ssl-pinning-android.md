---
layout: post
title: "Bypassing SSL pinning on Android in 2021"
date: 2021-08-21
tags: mobile-dev hacking
permalink: ssl-pinning-android
---
<!-- ![1.png]({{site.url}}/assets/resources-ssl-pinning-android/1.png) -->

> This article is a braindump of how I was successful in bypassing SSL pinning on Android 11 in 2021.  Please see the acknowledgments at the end for the various guides that helped me get there!  
>
> The goal of this article was to understand the August Lock private API. If that's what you're interesting in learning more about too, this is the guide to follow.
`
<br>

### Prereqs
- A rooted Android phone (see my old guide on [rooting pixel 1](https://joshspicer.com/root-pixel-1)).  **Note for this article i'm using a rooted Pixel 4a.**
- Install some proxy/HTTP introspection application on your computer. I'm using a Mac with **[Proxyman](http://proxyman.io)** installed for this tutorial.
- Download the Android Debug Bridge (`adb`) binary, bundled as a part of Android [platform tools](https://developer.android.com/studio/command-line/adb)
- Install python3 and [frida](https://frida.re)

## Setup
### Install Frida on your rooted device

You'll want to start the [`frida-server`](https://frida.re/docs/android/) on your android phone.  

I did this by installing the frida-server package in `magisk` itself (just open the app and search `Frida` in the packages panel).  You may also start `frida-server` manually. 

Starting frida on your android device sets 

### ADB & Frida

In Developer settings, turn on `USB debugging`.  Plugging your device into your computer, you should be able to issue the following commands.


```bash
$ ~/platform-tools/adb  devices -l
List of devices attached
XXXXXXXXXXXXXX         device usb:XXXXXXX product:sunfish model:Pixel_4a device:sunfish transport_id:1

$ frida-ps -U
 PID  Name
----  -----------------------------------------------------------------------------------------------------
6598   Android Auto
8348   August
6954   Calendar
7456   Chrome
 956      android.hardware.camera.provider@2.6-service-google
 957      android.hardware.cas@1.2-service
 624      android.hardware.configstore@1.1-service
 958      android.hardware.confirmationui@1.0-service-google
1540      logcat
 572      logd
 ...
1284      lowi-server
 900      magiskd
1184      media.codec
1173      media.extractor
 990      media.hwcodec
1174      media.metrics
1201      media.swcodec
1177      mediaserver
 996      modem_svc
 997      msm_irqbalance
 925      netd
1187      netmgrd
2463      org.codeaurora.ims
...
 ```

### Set up MITM proxy

Set up a local proxy, sending your Android phone's connection through something like [Proxyman](http://proxyman.io) with a trusted SSL cert.  You'll want to be able to see your Android app's traffic in the proxyman UI, even if you aren't able to view the actual HTTP bodies.

For more info for MITM'ing your device, see Proxyman's guide on:

- [Proxying an Android device](https://docs.proxyman.io/debug-devices/android-device)
- [How to install and trust self-signed certificates on Android 11?](https://proxyman.io/posts/2020-09-29-Install-And-Trust-Self-Signed-Certificate-On-Android-11).

You'll also want to save the `.crt` file to your Android phone's Downloads - we'll need this certificate in the next step.

### Copy ssl cert to data directory

Here we'll copy the SSL cert to place the frida script will be able to read it.

```bash
$ adb shell cp /storage/self/primary/Download/proxyman-ca.pem.crt /data/local/tmp/cert-der.crt

$ adb shell ls /data/local/tmp

cert-der.crt
re.frida.server
```

### Running a frida script

Frida is an instrumentation platform that allows us to dynamically no-op or reimplement specified system functions.

A couple ssl-pinning scripts i've found online are by [@pcipolloni](https://codeshare.frida.re/@pcipolloni/universal-android-ssl-pinning-bypass-with-frida/) and [httptoolkit](https://github.com/httptoolkit/frida-android-unpinning).  Choose one of these scripts, or write your own, and push that script to your device.

EDIT (Dec 12, 2021): I've have recent success with [this script](https://codeshare.frida.re/@akabe1/frida-multiple-unpinning/)

 ```bash
$ adb push ~/frida_scripts/frida_ssl_pinning /data/local/tmp

/home/josh/frida_scripts/frida_ssl_pinni...1 file pushed, 0 skipped. 0.3 MB/s (2972 bytes in 0.011s)

$ adb shell ls /data/local/tmp
cert-der.crt
frida_ssl_pinning
re.frida.server
 ```

 Runing the script looks like so:

 ```
[~/frida_ssl_pinning]$ frida -U -f com.august.luna -l script.js --no-pause
     ____
    / _  |   Frida 15.0.13 - A world-class dynamic instrumentation toolkit
   | (_| |
    > _  |   Commands:
   /_/ |_|       help      -> Displays the help system
   . . . .       object?   -> Display information about 'object'
   . . . .       exit/quit -> Exit
   . . . .
   . . . .   More info at https://frida.re/docs/home/
Spawned `com.august.luna`. Resuming main thread!
[Pixel 4a::com.august.luna]->
[.] Cert Pinning Bypass/Re-Pinning
[+] Loading our CA...
[o] Our CA Info: OU=https://proxyman.io, CN="Proxyman CA (7 Feb 2021, harper.local)", O=Proxyman Inc, L=Singapore, C=SG
[+] Creating a KeyStore for our CA...
[+] Creating a TrustManager that trusts the CA in our KeyStore...
[+] Our TrustManager is ready...
[+] Hijacking SSLContext methods now...
[-] Waiting for the app to invoke SSLContext.init()...
[o] App invoked javax.net.ssl.SSLContext.init...
[+] SSLContext initialized with our custom TrustManager!
[o] App invoked javax.net.ssl.SSLContext.init...
[+] SSLContext initialized with our custom TrustManager!
```

Moving back to Proxyman, you can validate that the SSL unpinning scripts were either successful or unsuccessful.  

In the case of the August app, the scripts above did not allow 100% of requests to get through, but regardless may have ended up getting me the information I was looking for.  This technique could be combined with other techniques, such as downgrading to an older app version or trying to get the app into an uncommon error state.

## Previous work/references
- [nolanbrown.medium.com/](https://nolanbrown.medium.com/the-process-of-reverse-engineering-the-august-lock-api-9dbd12ab65cb)
- [netspi.com](https://www.netspi.com/blog/technical/four-ways-bypass-android-ssl-verification-certificate-pinning/)
- [httptoolkit.tech](https://httptoolkit.tech/blog/frida-certificate-pinning/)
