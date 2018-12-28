---
layout: post
title: Cinnamon Photo of the Day
date: 2017-08-17
permalink: cinnamon
---
> I have a cat named Cinnamon. She's the best. Here's code that displays a new
> photo of her daily.

```
// Pick a photo of the day
// mod how many pictures I currently have on this server.
  var date = new Date()
  var num = (date.getDay() * date.getYear() * date.getMonth()) % 119
  var photo = "../assets/cinnamon/" + num + ".jpg"
  document.getElementById("cinnaImage").src = photo;
```
<img style="border: 3px;border-style: solid;" class="cinnamon" id="cinnaImage" src=""/>

<script src="../../js/whichCinnamon.js"></script>
