---
layout: post
title: "Spotify \"Now Playing\" v2"
date: 2021-08-25
permalink: spotify-now-playing-azure
tags: spotify aws music
---
<!-- ![1.png]({{site.url}}/assets/resources-spotify-now-playing-azure/1.png) -->


The most astute readers of this blog would've noticed that for the past couple months, its homepage has been missing its characteristic [Josh is listening to "XXX" on Spotify]({{site.url}}/spotify-now-playing). As my final AWS credits from "student-hood" expired, I decided it was time to move this script over to a new home.  

Functionally, the new project you'll find [**on GitHub**](https://github.com/joshspicer/spotify-now-playing-azure) is nearly identical, but now it's packaged into an easily to deploy [Azure Function](https://docs.microsoft.com/en-us/azure/azure-functions/functions-overview).  All you need is to gather some Spotify secrets, and press the deploy button in the VSCode extension.

![1.png]({{site.url}}/assets/resources-spotify-now-playing-azure/1.png)

## Setup

Check the setup information in the [GitHub repo's README](https://github.com/joshspicer/spotify-now-playing-azure#setup)
