---
layout: post
title: Cinnamon Photo of the Day
date: 2017-08-17
permalink: cinnamon
---
> I have a cat named Cinnamon. She's the best. Here's a daily photo of her.
> (I'd recommend bookmarking this page...)

```javascript
  // Pick a photo of the day
  var date = new Date()
  var num = (date.getDay() * date.getYear() * date.getMonth()) % 119
  var photo = "../assets/cinnamon/" + num + ".jpg"
  document.getElementById("cinnaImage").src = photo;
```
<img style="border: 3px;border-style: solid;" class="cinnamon" id="cinnaImage" src=""/>

<script src="../../js/whichCinnamon.js"></script>
