---
layout: post
title: "Reverse Engineering my A/C into a HomeKit Accessory"
date: 2021-07-05
tags: homelab hacking
permalink: aircon-homekit
---
<!-- ![1.png]({{site.url}}/assets/resources-reverse-engineer-ac/1.png) -->

> As a part of homekit-ifying my apartment, i've been wanting to make my window A/C unit a bit smarter. I have a [Keystone remote-controlled A/C](https://www.amazon.com/gp/product/B084KWVDLM) - below is the journey of understanding how the remote talks to the A/C unit, and how to use some little IR LEDS and an ESP 8266 to open the A/C up to Homekit.
>
> See my [previous HomeKit article for more info on initial setup]({{site.url}}/homekit-esp8266).


## Protocol

First step was to see what messages were being sent out of the A/C's remote control.  To do so, I purchased a little 
[IR receiver (VS1838B)](https://www.amazon.com/gp/product/B06XYNDRGF) and hooked it up to my breadboard and ESP module with the pin out seen here:

![1.png]({{site.url}}/assets/resources-reverse-engineer-ac/1.png)

[I used IRremoteESP8266's IRrecvDumpV3](https://github.com/crankyoldgit/IRremoteESP8266/blob/master/examples/IRrecvDumpV3/IRrecvDumpV3.ino) to inspect the output.  This library contains a lot of pre-reversed-engineered protocols, and as it turned out the IRrecvDumpV3 correctly identified the protocol.


The result of the dump was really detail-rich:

```
Timestamp : 000080.500
Library   : v2.7.19

Protocol  : MIDEA
Code      : 0xA10C7EFFFFF3 (48 Bits)
Mesg Desc.: Type: 1 (Command), Power: Off, Mode: 4 (Fan), Celsius: Off, Temp: 33C/92F, On Timer: Off, Off Timer: Off, Fan: 1 (Low), Sleep: Off, Swing(V) Toggle: Off, Econo Toggle: Off, Turbo Toggle: Off, Light Toggle: Off
uint16_t rawData[199] = {4420, 4400,  558, 1594,  558, 516,  558, 1594,  558, 516,  560, 516,  558, 516,  558, 516,  560, 1594,  558, 516,  560, 516,  558, 516,  558, 516,  560, 1594,  558, 1592,  558, 518,  558, 516,  558, 516,  558, 1594,  558, 1594,  558, 1592,  558, 1594,  558, 1594,  558, 1594,  558, 516,  558, 1594,  560, 1592,  558, 1594,  558, 1592,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1592,  560, 1594,  558, 1594,  560, 1592,  560, 1592,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 516,  558, 516,  560, 1594,  558, 1594,  558, 5190,  4422, 4400,  558, 518,  558, 1594,  558, 518,  558, 1594,  558, 1596,  556, 1594,  558, 1596,  558, 516,  560, 1594,  558, 1594,  558, 1594,  556, 1594,  558, 518,  558, 516,  558, 1594,  558, 1594,  558, 1594,  558, 518,  558, 518,  558, 516,  560, 516,  558, 518,  558, 518,  558, 1596,  556, 518,  558, 516,  558, 518,  558, 518,  558, 518,  558, 518,  558, 516,  558, 518,  558, 516,  558, 518,  558, 516,  558, 518,  558, 518,  558, 518,  558, 516,  558, 518,  558, 518,  558, 516,  558, 518,  558, 518,  558, 1594,  558, 1594,  558, 516,  558, 518,  558};  // MIDEA A10C7EFFFFF3
uint64_t data = 0xA10C7EFFFFF3;


Timestamp : 000098.968
Library   : v2.7.19

Protocol  : MIDEA
Code      : 0xA18C7EFFFF73 (48 Bits)
Mesg Desc.: Type: 1 (Command), Power: On, Mode: 4 (Fan), Celsius: Off, Temp: 33C/92F, On Timer: Off, Off Timer: Off, Fan: 1 (Low), Sleep: Off, Swing(V) Toggle: Off, Econo Toggle: Off, Turbo Toggle: Off, Light Toggle: Off
uint16_t rawData[199] = {4420, 4398,  560, 1594,  558, 518,  558, 1594,  558, 516,  560, 516,  558, 518,  558, 516,  560, 1594,  558, 1594,  558, 516,  560, 516,  560, 516,  558, 1594,  558, 1594,  558, 516,  560, 516,  558, 516,  558, 1594,  558, 1594,  558, 1594,  558, 1592,  558, 1594,  558, 1592,  558, 516,  560, 1592,  560, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  556, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 518,  558, 1594,  558, 1594,  558, 1594,  558, 516,  558, 518,  558, 1594,  558, 1594,  558, 5190,  4420, 4400,  558, 516,  558, 1594,  588, 488,  558, 1594,  586, 1564,  588, 1566,  586, 1566,  586, 488,  586, 488,  588, 1564,  586, 1566,  586, 1566,  586, 488,  588, 488,  586, 1566,  586, 1566,  586, 1564,  586, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 1564,  588, 488,  588, 486,  588, 488,  588, 488,  588, 488,  586, 488,  588, 488,  586, 488,  586, 488,  588, 488,  588, 488,  586, 488,  588, 488,  588, 488,  588, 488,  586, 488,  586, 1566,  586, 490,  588, 488,  586, 490,  586, 1564,  588, 1564,  586, 488,  588, 488,  586};  // MIDEA A18C7EFFFF73
uint64_t data = 0xA18C7EFFFF73;


Timestamp : 000114.744
Library   : v2.7.19

Protocol  : MIDEA
Code      : 0xA18267FFFF6A (48 Bits)
Mesg Desc.: Type: 1 (Command), Power: On, Mode: 2 (Auto), Celsius: Off, Temp: 21C/69F, On Timer: Off, Off Timer: Off, Fan: 0 (Auto), Sleep: Off, Swing(V) Toggle: Off, Econo Toggle: Off, Turbo Toggle: Off, Light Toggle: Off
uint16_t rawData[199] = {4422, 4398,  560, 1594,  558, 516,  560, 1592,  560, 516,  560, 514,  560, 516,  562, 512,  560, 1590,  562, 1590,  560, 516,  560, 514,  560, 516,  560, 514,  560, 516,  560, 1592,  560, 516,  560, 516,  562, 1590,  560, 1592,  562, 514,  560, 516,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  558, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1594,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 516,  560, 1592,  560, 1592,  560, 516,  560, 1592,  560, 516,  560, 1592,  560, 516,  560, 5190,  4422, 4398,  560, 514,  560, 1592,  560, 516,  560, 1594,  560, 1592,  560, 1592,  560, 1592,  560, 516,  560, 516,  560, 1592,  560, 1592,  560, 1592,  560, 1594,  562, 1590,  560, 516,  560, 1592,  560, 1592,  560, 516,  560, 516,  560, 1592,  560, 1592,  560, 516,  560, 516,  560, 516,  560, 516,  560, 516,  560, 516,  560, 516,  560, 516,  562, 512,  560, 516,  560, 516,  560, 516,  560, 516,  558, 516,  560, 516,  560, 516,  560, 516,  560, 516,  560, 516,  560, 1592,  560, 516,  560, 516,  560, 1592,  560, 516,  560, 1592,  560, 516,  560, 1592,  562};  // MIDEA A18267FFFF6A
uint64_t data = 0xA18267FFFF6A;


Timestamp : 000138.675
Library   : v2.7.19

Protocol  : MIDEA
Code      : 0xA18268FFFF64 (48 Bits)
Mesg Desc.: Type: 1 (Command), Power: On, Mode: 2 (Auto), Celsius: Off, Temp: 21C/70F, On Timer: Off, Off Timer: Off, Fan: 0 (Auto), Sleep: Off, Swing(V) Toggle: Off, Econo Toggle: Off, Turbo Toggle: Off, Light Toggle: Off
uint16_t rawData[199] = {4420, 4400,  558, 1592,  560, 516,  560, 1592,  560, 518,  558, 518,  558, 516,  562, 512,  560, 1594,  560, 1590,  558, 516,  560, 516,  558, 516,  560, 516,  560, 516,  558, 1594,  558, 516,  560, 516,  558, 1592,  560, 1592,  558, 518,  560, 1592,  560, 516,  560, 516,  562, 512,  560, 1592,  560, 1592,  560, 1592,  560, 1594,  558, 1592,  586, 1566,  560, 1592,  560, 1592,  558, 1594,  560, 1592,  560, 1592,  560, 1594,  558, 1592,  560, 1594,  558, 1594,  560, 1594,  558, 516,  560, 1592,  560, 1594,  558, 516,  558, 516,  560, 1592,  560, 516,  560, 516,  558, 5190,  4450, 4372,  586, 490,  586, 1564,  588, 488,  558, 1594,  586, 1564,  588, 1564,  586, 1564,  588, 488,  586, 488,  588, 1564,  588, 1564,  588, 1566,  586, 1566,  588, 1562,  588, 488,  588, 1564,  588, 1564,  588, 488,  588, 488,  588, 1564,  588, 488,  588, 1564,  590, 1562,  588, 1564,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  590, 486,  588, 488,  588, 486,  588, 488,  588, 488,  588, 488,  586, 488,  588, 486,  588, 488,  588, 1564,  588, 488,  588, 488,  588, 1564,  588, 1562,  588, 488,  588, 1564,  588, 1564,  588};  // MIDEA A18268FFFF64
uint64_t data = 0xA18268FFFF64;


Timestamp : 000144.930
Library   : v2.7.19

Protocol  : MIDEA
Code      : 0xA18269FFFF65 (48 Bits)
Mesg Desc.: Type: 1 (Command), Power: On, Mode: 2 (Auto), Celsius: Off, Temp: 22C/71F, On Timer: Off, Off Timer: Off, Fan: 0 (Auto), Sleep: Off, Swing(V) Toggle: Off, Econo Toggle: Off, Turbo Toggle: Off, Light Toggle: Off
uint16_t rawData[199] = {4422, 4400,  558, 1592,  560, 516,  560, 1592,  560, 516,  558, 516,  558, 516,  560, 516,  558, 1592,  562, 1590,  558, 516,  560, 516,  560, 516,  558, 516,  558, 516,  560, 1592,  560, 516,  560, 516,  560, 1590,  558, 1594,  558, 516,  560, 1592,  558, 516,  558, 518,  562, 1590,  560, 1592,  560, 1592,  558, 1592,  560, 1592,  562, 1590,  558, 1592,  560, 1592,  560, 1592,  560, 1590,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  562, 1592,  558, 1594,  558, 1592,  560, 516,  560, 1592,  560, 1592,  560, 516,  558, 516,  560, 1592,  558, 516,  560, 1594,  560, 5186,  4422, 4398,  560, 516,  560, 1592,  560, 516,  558, 1592,  560, 1592,  558, 1594,  558, 1592,  588, 488,  558, 516,  562, 1590,  558, 1594,  558, 1592,  588, 1564,  562, 1590,  586, 488,  588, 1564,  558, 1592,  588, 488,  586, 490,  588, 1564,  586, 488,  588, 1564,  586, 1564,  588, 488,  586, 490,  588, 488,  588, 488,  588, 488,  586, 488,  562, 514,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 1564,  588, 488,  586, 488,  588, 1564,  588, 1566,  588, 488,  588, 1564,  588, 488,  588};  // MIDEA A18269FFFF65
uint64_t data = 0xA18269FFFF65;


Timestamp : 000148.631
Library   : v2.7.19

Protocol  : MIDEA
Code      : 0xA18268FFFF64 (48 Bits)
Mesg Desc.: Type: 1 (Command), Power: On, Mode: 2 (Auto), Celsius: Off, Temp: 21C/70F, On Timer: Off, Off Timer: Off, Fan: 0 (Auto), Sleep: Off, Swing(V) Toggle: Off, Econo Toggle: Off, Turbo Toggle: Off, Light Toggle: Off
uint16_t rawData[199] = {4420, 4400,  560, 1592,  560, 516,  558, 1594,  558, 516,  558, 516,  560, 516,  558, 518,  558, 1592,  562, 1590,  560, 516,  560, 516,  560, 516,  560, 516,  560, 516,  558, 1592,  560, 516,  560, 516,  562, 1590,  560, 1592,  560, 516,  558, 1592,  560, 516,  560, 516,  562, 514,  558, 1592,  558, 1594,  558, 1592,  560, 1592,  558, 1592,  558, 1594,  558, 1594,  558, 1594,  558, 1592,  558, 1592,  560, 1594,  558, 1592,  560, 1592,  558, 1592,  560, 1594,  558, 1592,  560, 516,  558, 1592,  560, 1594,  558, 516,  560, 514,  560, 1592,  560, 516,  560, 516,  558, 5188,  4422, 4400,  558, 516,  560, 1594,  558, 516,  558, 1592,  560, 1592,  560, 1592,  562, 1590,  560, 516,  558, 516,  558, 1594,  558, 1592,  558, 1594,  558, 1592,  560, 1592,  560, 516,  560, 1592,  560, 1592,  560, 516,  560, 516,  560, 1592,  586, 490,  560, 1592,  560, 1592,  562, 1590,  560, 516,  562, 514,  588, 488,  588, 490,  558, 516,  586, 488,  588, 488,  588, 488,  560, 516,  586, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  586, 1566,  586, 488,  588, 490,  588, 1564,  586, 1566,  586, 488,  588, 1564,  588, 1564,  586};  // MIDEA A18268FFFF64
uint64_t data = 0xA18268FFFF64;


Timestamp : 000151.030
Library   : v2.7.19

Protocol  : MIDEA
Code      : 0xA18267FFFF6A (48 Bits)
Mesg Desc.: Type: 1 (Command), Power: On, Mode: 2 (Auto), Celsius: Off, Temp: 21C/69F, On Timer: Off, Off Timer: Off, Fan: 0 (Auto), Sleep: Off, Swing(V) Toggle: Off, Econo Toggle: Off, Turbo Toggle: Off, Light Toggle: Off
uint16_t rawData[199] = {4420, 4398,  560, 1592,  558, 516,  560, 1592,  560, 516,  558, 516,  560, 516,  562, 514,  560, 1592,  562, 1590,  560, 516,  560, 516,  558, 516,  560, 516,  558, 516,  560, 1592,  558, 516,  560, 516,  560, 1592,  560, 1592,  560, 516,  560, 516,  560, 1594,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  558, 1594,  558, 1594,  560, 1592,  560, 1592,  558, 1594,  558, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  558, 516,  560, 1592,  558, 1592,  558, 516,  560, 1592,  560, 516,  560, 1592,  560, 516,  560, 5190,  4420, 4400,  560, 514,  560, 1594,  560, 514,  560, 1592,  560, 1592,  558, 1592,  560, 1592,  560, 516,  560, 514,  560, 1594,  558, 1592,  560, 1592,  560, 1592,  562, 1590,  586, 488,  588, 1566,  558, 1592,  586, 490,  560, 516,  562, 1590,  560, 1592,  586, 490,  558, 516,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  562, 514,  588, 488,  588, 488,  588, 488,  588, 488,  560, 516,  588, 488,  588, 486,  588, 488,  588, 488,  586, 488,  588, 488,  588, 1564,  588, 488,  588, 488,  588, 1564,  588, 488,  588, 1564,  588, 488,  588, 1564,  588};  // MIDEA A18267FFFF6A
uint64_t data = 0xA18267FFFF6A;


Timestamp : 000160.799
Library   : v2.7.19

Protocol  : MIDEA
Code      : 0xA10267FFFFEA (48 Bits)
Mesg Desc.: Type: 1 (Command), Power: Off, Mode: 2 (Auto), Celsius: Off, Temp: 21C/69F, On Timer: Off, Off Timer: Off, Fan: 0 (Auto), Sleep: Off, Swing(V) Toggle: Off, Econo Toggle: Off, Turbo Toggle: Off, Light Toggle: Off
uint16_t rawData[199] = {4420, 4400,  560, 1592,  560, 516,  560, 1592,  558, 516,  558, 516,  560, 516,  560, 516,  560, 1592,  560, 516,  560, 516,  560, 516,  558, 516,  560, 516,  558, 516,  560, 1592,  558, 518,  558, 516,  558, 1594,  558, 1592,  560, 516,  560, 516,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1594,  558, 1594,  558, 1592,  560, 1594,  558, 1592,  560, 1594,  558, 1594,  560, 1592,  560, 1594,  558, 1594,  558, 1592,  560, 1592,  560, 1592,  560, 1592,  560, 1594,  558, 1592,  560, 1594,  558, 516,  560, 1594,  558, 516,  558, 1594,  558, 516,  560, 5190,  4420, 4400,  558, 518,  558, 1592,  558, 518,  562, 1590,  560, 1592,  560, 1592,  560, 1592,  558, 518,  558, 1592,  560, 1592,  558, 1592,  560, 1592,  560, 1592,  586, 1566,  558, 516,  558, 1594,  558, 1594,  558, 516,  560, 516,  558, 1592,  588, 1564,  560, 516,  560, 516,  560, 516,  588, 488,  586, 490,  586, 488,  588, 488,  562, 514,  586, 488,  560, 516,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  588, 488,  586, 1564,  588, 488,  588, 1564,  588, 488,  588, 1564,  588};  // MIDEA A10267FFFFEA
uint64_t data = 0xA10267FFFFEA;
```

As a proof of concept I wrote up a little arduino sketch and hooked up three IR LEDs in parallel:

![2.png]({{site.url}}/assets/resources-reverse-engineer-ac/2.JPG)

![3.png]({{site.url}}/assets/resources-reverse-engineer-ac/3.JPG)

![4.png]({{site.url}}/assets/resources-reverse-engineer-ac/4.JPG)


I then ran the following sketch, copying the raw bytes from a previous capture - turning the A/C on!


```arduino
#include <Arduino.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <ir_Midea.h>

const uint16_t irLed = 4;

uint16_t rawData[199] = {4420, 4400,  560, 1592,  558, 518,  558, 1592,  558, 516,  560, 516,  558, 516,  558, 518,  558, 1594,  558, 1592,  558, 518,  558, 516,  560, 516,  558, 1594,  558, 518,  558, 516,  558, 516,  558, 518,  558, 1594,  558, 1594,  560, 516,  558, 516,  558, 1594,  558, 1594,  558, 516,  560, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1594,  558, 1592,  558, 1594,  558, 1594,  558, 1594,  558, 516,  560, 1594,  558, 1594,  560, 514,  558, 516,  560, 516,  558, 518,  558, 516,  560, 5188,  4420, 4400,  558, 516,  560, 1592,  558, 516,  560, 1592,  558, 1594,  558, 1594,  558, 1594,  558, 516,  560, 516,  558, 1594,  558, 1594,  558, 1592,  558, 516,  558, 1594,  558, 1594,  584, 1566,  558, 1594,  558, 516,  558, 516,  586, 1566,  558, 1594,  558, 518,  558, 516,  586, 1566,  558, 518,  586, 488,  586, 488,  588, 488,  560, 514,  590, 486,  588, 488,  558, 516,  586, 490,  586, 488,  586, 488,  586, 488,  588, 488,  586, 490,  586, 490,  586, 488,  562, 1592,  586, 488,  586, 488,  586, 1566,  586, 1566,  590, 1560,  558, 1594,  558, 1594,  588};  // MIDEA A18866FFFF60


IRsend irsend(irLed);

void setup() {

  irsend.begin();
  Serial.begin(115200);

}

void loop() {
  irsend.sendRaw(rawData, 199, 38);
  delay(2000);
}


```

The previously mentioned ESP library has an `ir_Midea` class which implements the protocol.  Simply creating an instance of the [`IRMideaAc`](https://github.com/crankyoldgit/IRremoteESP8266/blob/master/src/ir_Midea.h) let me interface quickly with the A/C!

```arduino
#include <Arduino.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <ir_Midea.h>

const uint16_t irLed = 4;
IRMideaAC ac(irLed);

void setup() {
  ac.begin();
  Serial.begin(115200);

  delay(200);
  Serial.println("Setup Complete.");
}

void loop() {
  ac.on();
  ac.setFan(1);

  ac.setTemp(65,false);
  ac.send();

  Serial.println("waiting...");
  delay(5000);

  ac.off();
  ac.send();
  delay(5000);

}
```

## + HomeKit

Utilizing my previous [ESP HomeKit boilerplate]({{site.url}}/homekit-esp8266), and by referring to the [HomeKit specificaton](https://developer.apple.com/homekit/specification/) published by Apple, I implemented a `Heater Cooler` accessory with several services. 


```C
chomekit_accessory_t *accessories[] = {
    HOMEKIT_ACCESSORY(.id=1, .category=homekit_accessory_category_air_conditioner, .services=(homekit_service_t*[]) {
         HOMEKIT_SERVICE(ACCESSORY_INFORMATION, .characteristics=(homekit_characteristic_t*[]) {
                HOMEKIT_CHARACTERISTIC(NAME, "Air Conditioner"),
                HOMEKIT_CHARACTERISTIC(MANUFACTURER, "spicer.dev"),
                HOMEKIT_CHARACTERISTIC(SERIAL_NUMBER, "0000001"),
                HOMEKIT_CHARACTERISTIC(MODEL, "ESP8266"),
                HOMEKIT_CHARACTERISTIC(FIRMWARE_REVISION, "1.0"),
                HOMEKIT_CHARACTERISTIC(IDENTIFY, my_accessory_identify),
                NULL
         }),
       HOMEKIT_SERVICE(HEATER_COOLER, .primary=true, .characteristics=(homekit_characteristic_t*[]) {
           &cooler_active,
           &current_temp,
           &current_state,
           &target_state,
           &rotation_speed,
           &cooling_threshold,
           NULL
       }),
        NULL
    }),
      NULL
};

```

Each service has a callback which queues the appropriate IR command, and on each loop, an IR payload is sent.

```C
void loop() {
  my_homekit_loop();
  delay(10);

  if (queueCommand)
  {
    Serial.write("Sending AC Command....\n");
    ac.send();
    flipQueueCommand(false);
  }

}
```
<br>

---
<br>

The entire Arduino sketch can be **[found on GitHub](https://github.com/joshspicer/keystone-AC-homekit-esp8266)**.  

Changing the Wifi information will let the module connect to your LAN, which will then make the module discoverable in your phone's Home app.

```

...................................................................................................................................................................................................................................................................
WiFi connected, IP:  10.77.6.140
starting my_homekit_setup
about to call arduino_homekit_setup
>>> [  14008] HomeKit: Starting server
>>> [  14019] HomeKit: Using existing accessory ID: BF:A6:FD:8B:AA:44
>>> [  14025] HomeKit: Preiniting pairing context
>>> [  14030] HomeKit: Using user-specified password: 121-33-121
>>> [  14050] HomeKit: Call s_mp_exptmod in integer.c, original winsize 6
>>> [  20763] HomeKit: Call s_mp_exptmod in integer.c, original winsize 5
>>> [  24193] HomeKit: Preinit pairing context success
>>> [  24198] HomeKit: Configuring MDNS
>>> [  24203] HomeKit: MDNS begin: AirCon, IP: 10.77.6.140
>>> [  24209] HomeKit: Init server over
exiting my_homekit_setup
Free heap: 40568, HomeKit clients: 0
Free heap: 41056, HomeKit clients: 0
Free heap: 41104, HomeKit clients: 0
...
```

<br>

![1.png]({{site.url}}/assets/resources-reverse-engineer-ac/5.jpeg)
