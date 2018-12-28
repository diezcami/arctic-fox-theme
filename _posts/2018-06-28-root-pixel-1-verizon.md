---
layout: post
title: Rooting your Bootlocked Pixel Phone (Verizon Edition)
date: 2018-06-28
permalink: root-pixel-1
favorite: "true"
---

I bought a new Pixel phone on Ebay a couple months ago for testing an Android app i'm developing. To my surprise,
the phone I received in the mail was not the unlocked Google version I thought I ordered (with an unlocked bootloader), but rather the locked down
Verizon version.
<br><br>
I was hoping to eventually root the device in order to play around with some pentesting tools (specifically Frida). Sadly, I wasn't able
to find an easy solution _until now_.
<br><br>

<h2>Unlock Bootloader</h2>

This morning I saw a [post](https://forum.xda-developers.com/pixel-xl/how-to/how-to-unlock-bootloader-verizon-pixel-t3796030) on the xda forums by user **burduli**,
illustrating how he unlocked the bootloader on a Verizon Pixel. His article was posted on May 27th, 2018. It's taken almost **two years** since the phone's release for this simple bootloader workaround to be found!
<br><br>
The steps are as follows, adapted slightly based on my experience and environment (Ubuntu):

1.  Remove Google account and PIN/Fingerprint from your device.
2.  Eject sim card from your device.
3.  Factory reset your device. Skip **everything** in the setup wizard.
4.  Go to Developer Options and [enable USB debugging](https://www.embarcadero.com/starthere/xe5/mobdevsetup/android/en/enabling_usb_debugging_on_an_android_device.html).
5.  Connect your phone to computer.
6.  Open terminal in adb directory and type
    `adb shell pm uninstall --user 0 com.android.phone`
7.  Restart your device.
8.  Connect to WiFi, open Chrome and go to any website. (nobody knows why we do this??)
9.  Go to Developer Options and enable OEM unlocking.
10. Reboot into bootloader and via terminal run
    `fastboot oem unlock`
    or
    `fastboot flashing unlock`
11. Profit

<h3>Notes</h3>
- For `adb` and `fastboot`, I installed Android Studio on my machine and navigated to `~/Android/Sdk/platform-tools` when I wanted to use those programs. I had difficulty with the `fastboot` installed from apt that was attached to my PATH.
<br><br>
- I had to restart my phone twice to perform step 9. The first time, the OEM unlocking slider was grayed out. Others in the original post's comments had similar problems.
<br><br>
- If you see the error **"insufficient permissions for device error"**, you'll need to first kill the server `adb kill-server`, and then restart with root privs `sudo adb start-server`.
<br><br>
- Be aware that unlocking bootloader removes everything from your device. The fact that you factory restore in step 3 means you should be ok with this...

<h2>Rooting Prereqs</h2>

These are the requirements and files I found necessary.

- `adb` and `fastboot` (which you already have from the bootloader bit above)
- A cable to connect phone to computer
- ["SailFish" Pixel Factory Image v8.1-May](https://dl.google.com/dl/android/aosp/sailfish-opm4.171019.016.b1-factory-68c3a77d.zip) (downloaded to host computer)
- [twrp-3.2.1-2-sailfish.img](https://dl.twrp.me/sailfish/twrp-3.2.1-2-sailfish.img.html) (downloaded to host computer)
- [twrp-pixel-installer-sailfish-3.2.1-2.zip](https://dl.twrp.me/sailfish/twrp-pixel-installer-sailfish-3.2.1-2.zip.html) (downloaded to **device file system** BEFORE starting)
- [Magisk](https://forum.xda-developers.com/apps/magisk/official-magisk-v7-universal-systemless-t3473445) (downloaded to **device file system** BEFORE starting)

<h2>Get rid of all the Verizon</h2>

Now i'm not positive if this step is essential, but after encountering difficulty I decided to reimage the phone with an official Google
image. Either way, can't hurt to start with a clean slate.
<br><br>
Download the image above and follow this steps Google provides on their [factory images](https://developers.google.com/android/images) page.
Essentially, you'll want to unzip the image archive, plug in your device, and run the `flash-all.sh` it provides. You'll need to make sure the
correct `fastboot` is in your PATH. Mine wasn't, so I modified the four spots that `fastboot` was called in the script and wrote out the full path (`~/Android/Sdk/platform-tools/fastboot`).

<h2>Prep TWRP</h2>

First off, make sure to set a PIN number in the OS before continuing. You need a PIN so TWRP can decrypt and access the file system later.
<br><br>
I had no idea what TWRP was before this guide, but apparently it's a custom recovery tool used for installing custom software on your device. The way we
install TWRP is by first loading a temporary TWRP state onto the device, and then in that state overwriting our recovery partition with a full TWRP install.
<br><br>
Install the .img file from above, move it to your `platform-tools` folder and rename it to `twrp.img`.

`mv ~/Downloads/twrp-3.2.1-2-sailfish.img ~/Android/Sdk/platform-tools/twrp.img`

<h2>Load TWRP</h2>

Now we're ready to load TWRP onto our phone. Start bootloader mode by holding down **power button + volume down** and plug in your phone. If you see an Android lying on his back, you're in the right spot. Try running `fastboot devices` - you should see your device show up.

![bootloader]({{site.url}}/assets/rooting-guide/bootloader.png)

Boot from the twrp image we just moved to the `platform-tools` directory by issuing:

`fastboot boot twrp.img`

<h2>Install TWRP</h2>

Great! You should now be booted into the twrp interface.

![twrp-img]({{site.url}}/assets/rooting-guide/twrp.png)

Press the "install" button, navigate to your Downloads folder, and install the `twrp-pixel-installer-sailfish-3.2.1-2.zip` you downloaded to your phone earlier. Let that installation complete (hopefully with no errors).
<br><br>
Now go back a few steps to the page we started at, press the `restart` button, and then press `recovery`. You should now boot into a version of TWRP running entirely on your device. You can use TWRP to do a whole bunch of things...one of them being rooting the device.

<h2>Actually root the device</h2>

Same as last time! Press the "install" button, but this time you're installing the `Magisk` zip you downloaded at the start of this guide.
<br><br>
Like magic, your device is now rooted! I downloaded a free "Root checker" app from the Play Store to confirm. Enjoy!
