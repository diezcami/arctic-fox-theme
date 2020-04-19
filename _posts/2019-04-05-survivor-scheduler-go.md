---
layout: post
title: "Survivor: Northeastern Scheduler in Go"
date: 2019-04-05
permalink: survivor-scheduler
favorite: "true"
tags:
---

> [Survivor: Northeastern](http://survivornortheastern.com/) is a club at Northeastern
> that conducts an on-campus season of CBS's TV show "Survivor". I played in season 3 of
> this amazing club, and have been helping produce the show for others ever since.

This golang application aims to aid in collecting player weekly schedules and
calculating the best time for tribals, challenges, etc.

I've been interested in learning go for quite some time. I decided to start this project
with the **challenge of using nothing but golang** for the entire application. No external database,
no third-party libraries - just what the language allows for and natively supports.

## Data Storage

I wanted this project to be a holistic experience of golang,
so for persistent data storage I tried to stay away from traditional method.
I decided upon a simple file storage system.

### .survive file

All player data is stored in individual files titled `<player_name>.survive`.

The contents include seven 16-bit, 4-character hex-encoded numbers separated by a colon.
Each bit represents a half-hour increment, and each block indicated a day of the week (Sunday - 0, Saturday - 6).  
Historical availability is stored on previous lines. The "current" availability
is on the last line of the file.

```
0:0:0:0:0:0:0                       # Open availability
200:0:0:0:0:0:0
200:ffff:0:0:0:0:0                  # "Fully booked" on Monday
200:100:100:0:0:0:0
ffff:ffff:ffff:ffff:ffff:ffff:ffff  # Indicates NO free time
ffff:467:ffff:ffff:a4b6:ffff:addd   # Current Availability program will reference

```

## Getting Started

After compiling the go binary, `go build main.go`, starting the application is
as simple as running the produced binary.

The binary will look for a `conf` file in the same directory. If found, the game
will initialize itself.

### conf file

The `conf` file is simple a newline-separated list of player names, like so:

```
Josh
Mike
Mary
Ralph
```

Upon initialization, the conf file will be renamed to `conf.processed`. In addition,
survive files for each player will be initialized. Keep **all** of these files in the same
directory as the binary, as these files store necessary information to keep the game
persistent.

If all goes well, you will be greeted with a similar looking screen in your
web browser

![running](https://raw.githubusercontent.com/joshspicer/Survivor-Scheduler/master/images/running.png)

## Usage

Player can individually interact with their schedules by visiting the homepage
and clicking their name, or visiting `http://<server-root>/edit/<player-name>`

The club logistics manager can visit `http://<server-root>/manage` to see
aggregated player schedules.

## Source

You can find the source code on my [github page](https://github.com/joshspicer/Survivor-Scheduler).
