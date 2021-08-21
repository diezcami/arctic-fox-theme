---
layout: post
title: "Bypassing SSL pinning on Android in 2021"
date: 2021-08-21
permalink: ssl-pinning-android
---
<!-- ![1.png]({{site.url}}/assets/resources-ssl-pinning-android/1.png) -->

> Motivation [Link to post on august lock one-time password](...)

----

[Previous work](https://nolanbrown.medium.com/the-process-of-reverse-engineering-the-august-lock-api-9dbd12ab65cb)


[Frida ssl guide](https://www.netspi.com/blog/technical/four-ways-bypass-android-ssl-verification-certificate-pinning/)
[guide 2](https://httptoolkit.tech/blog/frida-certificate-pinning/)

### Prereqs
- Root your Android phone ([rooting pixel 1](https://joshspicer.com/root-pixel-1)) - i'm now using a [Pixel 4a](...)
- Install some proxy application on your computer (I'm using a Mac with Proxyman installed for this tutorial)

## Setup

### Install Frida

TODO: Install frida server via magisk
TODO: Install Frida on your machine

### Set up MITM proxy

TODO: Proxy your Android phone's connection through something like [Proxyman](http://proxyman.io) with an SSL cert

* Save the `.crt` file to your Android phone's Downloads
* Trust the SSL cert in Android settings


* Copy it over data directory

```bash
$ adb shell cp /storage/self/primary/Download/proxyman-ca.pem.crt /data/local/tmp/cert-der.crt

$ adb shell ls /data/local/tmp
cert-der.crt
re.frida.server
```


### ADB & Frida

1. Turn on USB debugging in Developer Settings 

Make sure you see the following:

```
$ ~/Documents/platform-tools/adb devices -l
List of devices attached
XXXXXXXXXXXXXX         device usb:XXXXXXX product:sunfish model:Pixel_4a device:sunfish transport_id:1

]$ frida-ps -U
 PID  Name
----  -----------------------------------------------------------------------------------------------------
6598   Android Auto
8348   August
6954   Calendar
7456   Chrome
7197   Clock
7159   Contacts
7335   Gmail
3953   Google
8530   Google News
3868   Google Play Store
7809   Google TV
8420   Home
4234   Messages
7224   Phone
5475   Pixel Tips
2569   Settings
8040   YouTube
6844   YouTube Music
2394      .dataservices
2414      .qtidataservices
2506      .qtidataservices
6661      adbd
1131      adsprpcd
1135      adsprpcd
1137      adsprpcd
 954      android.hardware.audio.service
1223      android.hardware.biometrics.fingerprint@2.2-service.fpc
 955      android.hardware.bluetooth@1.0-service-qti
 617      android.hardware.boot@1.1-service
 956      android.hardware.camera.provider@2.6-service-google
 957      android.hardware.cas@1.2-service
 624      android.hardware.configstore@1.1-service
 958      android.hardware.confirmationui@1.0-service-google
 959      android.hardware.contexthub@1.1-service.generic
 960      android.hardware.drm@1.0-service
 961      android.hardware.drm@1.3-service.clearkey
 962      android.hardware.drm@1.3-service.widevine
6361      android.hardware.dumpstate@1.1-service.sunfish
 618      android.hardware.gatekeeper@1.0-service-qti
 963      android.hardware.gnss@2.0-service-qti
 623      android.hardware.graphics.composer@2.4-service-sm8150
 964      android.hardware.health@2.1-service
 965      android.hardware.identity@1.0-service.citadel
2065      android.hardware.input.classifier@1.0-service
 583      android.hardware.keymaster@4.0-service-qti
 586      android.hardware.keymaster@4.1-service.citadel
 966      android.hardware.memtrack@1.0-service
 971      android.hardware.neuralnetworks@1.3-service-qti
 972      android.hardware.nfc@1.2-service.st
 685      android.hardware.power-service.pixel-libperfmgr
 976      android.hardware.power.stats@1.0-service.pixel
 909      android.hardware.rebootescrow-service.citadel
 977      android.hardware.secure_element@1.0-service.st
 978      android.hardware.sensors@2.0-service.multihal
 979      android.hardware.thermal@2.0-service.pixel
 980      android.hardware.usb@1.2-service.sunfish
 981      android.hardware.vibrator@1.3-service.sunfish
 982      android.hardware.weaver@1.0-service.citadel
 953      android.hidl.allocator@1.0-service
2855      android.process.acore
 616      android.system.suspend@1.0-service
 999      audioserver
1231      busybox
1154      cameraserver
1139      cdsprpcd
1230      chre
 585      citadeld
1152      cnd
1206      cnss-daemon
2142      com.android.bluetooth
2372      com.android.hbmsvmanager
3662      com.android.ims.rcsservice
2324      com.android.networkstack.process
3628      com.android.nfc
2541      com.android.phone
5871      com.android.providers.calendar
2485      com.android.se
2162      com.android.systemui
2266      com.breel.wallpapers20a
3689      com.google.SSRestartDetector
2705      com.google.android.apps.nexuslauncher
3183      com.google.android.apps.scone
3570      com.google.android.as
7060      com.google.android.carrier
7094      com.google.android.cellbroadcastreceiver
7116      com.google.android.configupdater
2800      com.google.android.euicc
2586      com.google.android.ext.services
7305      com.google.android.flipendo
3281      com.google.android.gms
2823      com.google.android.gms.persistent
7945      com.google.android.gms.ui
4894      com.google.android.gms.unstable
3594      com.google.android.googlequicksearchbox:interactor
2455      com.google.android.grilservice
7573      com.google.android.hardwareinfo
2896      com.google.android.ims
3521      com.google.android.inputmethod.latin
7594      com.google.android.onetimeinitializer
7623      com.google.android.packageinstaller
7652      com.google.android.partnersetup
6144      com.google.android.permissioncontroller
6688      com.google.android.projection.gearhead:shared
3767      com.google.android.providers.media.module
5425      com.google.android.settings.intelligence
7717      com.google.android.storagemanager
7748      com.google.android.syncadapters.contacts
7257      com.google.android.tts
7776      com.google.android.uvexposurereporter
5284      com.google.android.webview:sandboxed_process0:org.chromium.content.app.SandboxedProcessService0:0
8020      com.google.android.wfcactivation
8183      com.google.audio.hearing.visualization.accessibility.scribe
8213      com.google.euiccpixel
8237      com.google.intelligence.sense
8271      com.google.omadm.trigger
8294      com.google.pixel.livewallpaper
4165      com.google.process.gapps
3805      com.google.process.gservices
3300      com.qualcomm.qcrilmsgtunnel
3743      com.qualcomm.qti.services.secureui:sui_service
2435      com.qualcomm.qti.telephonyservice
8323      com.qualcomm.telephony
1000      credstore
1159      drmserver
1311      frida-server
1500      frida-server
1212      gatekeeperd
1001      gpuservice
 627      hardware.google.light@1.1-service
1893      hvdcp_opti
 575      hwservicemanager
1968      ims_rtp_daemon
1247      imsdatadaemon
1141      imsqmidaemon
1616      imsrcsd
1167      incidentd
   1      init
 531      init
1168      installd
 932      ip6tables-restore
 915      ipacm
 931      iptables-restore
1171      keystore
 573      lmkd
1207      loc_launcher
1364      logcat
1540      logcat
 572      logd
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
 998      pd-mapper
 983      pixelstats-vendor
1102      pm-proxy
 991      pm-service
1190      port-bridge
1197      qcrild
 992      qrtr-ns
 582      qseecomd
1002      rmt_storage
1003      sensors.qti
 574      servicemanager
 924      statsd
1180      storaged
 619      surfaceflinger
1523      system_server
 994      tftp_server
1129      thermal-engine
 683      time_daemon
 914      tombstoned
1120      traced
1117      traced_probes
 533      ueventd
1216      update_engine
 984      vendor.google.google_battery@1.1-service-vendor
 986      vendor.google.radioext@1.0-service
 987      vendor.google.wifi_ext@1.0-service-vendor
 625      vendor.qti.hardware.display.allocator-service
 594      vendor.qti.hardware.qseecom@1.0-service
 988      vendor.qti.hardware.qteeconnector@1.0-service
 989      vendor.qti.hardware.tui_comm@1.0-service-qti
 577      vndservicemanager
 602      vold
2273      webview_zygote
1182      wificond
2696      wpa_supplicant
1286      xtra-daemon
 927      zygote
 926      zygote64
 ```


For our case, we want to find the August app's running process.  Also make sure you can use adb to execute shell commands.

 ```
$ frida-ps -U | grep -i August
11111  August

$ adb shell ls /
acct
apex
bin
bugreports
cache
config
d
data
data_mirror
debug_ramdisk
default.prop
dev
dsp
etc
init
init.environ.rc
linkerconfig
...
...
 ```