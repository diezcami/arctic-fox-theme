---
layout: post
title: "Easily add Font Awesome icons to your Xamarin Forms app"
date: 2020-07-02
permalink: fa-xamarin
---

> Mobile apps need icons! Read on to learn how to add [Font Awesome's](https://fontawesome.com/) rich selection to your Forms App!

There are lots of (now outdated) guides online for adding Font Awesome icons to your Xamarin Forms app. As of Forms 4.5.530, the team introduced a [much easier way](https://devblogs.microsoft.com/xamarin/embedded-fonts-xamarin-forms/) with Embedded Fonts! No longer is any platform-specific configuration needed, nor any additional libraries. This method will just work for iOS, Android, and UWP. The devblog was great, but didn't specifically mention Font Awesome - so hereeee we go!

## Get the Latest FontAwesome

I grabbed the free Font Awesome 5 icons from [this download link](https://use.fontawesome.com/releases/v5.13.1/fontawesome-free-5.13.1-web.zip), which I found on [their website](https://fontawesome.com/how-to-use/on-the-web/setup/hosting-font-awesome-yourself).

The only file I ended up using from the zip was `webfonts/fa-solid-900.ttf`.

## Add the Font to your project

I'd suggest hopping over to the offical [devblog post](https://devblogs.microsoft.com/xamarin/embedded-fonts-xamarin-forms/) for this part. It's really simple though:

0. Ensure you're running Forms 4.5+.

1. Copy the `ttf` file from above anywhere in the shared project, and mark it as `EmbeddedResource`.

2. Add this line to your `AssemblyInfo.cs`

```csharp
using Xamarin.Forms;

...
[assembly: ExportFont("fa-solid-900.ttf", Alias = "FontAwesome")]
```

## Using the Font

You can select which icon you'd like to use by copying the unicode value from [the cheatsheet](https://fontawesome.com/cheatsheet/free/solid).

For example, I wanted a circular arrow icon for my app. I found `undo` from the cheatsheet with the unicode value `f0e2`.

You use the `Label` control with the "Text" value respresenting the unicode value of the icon you'd like to use. You'll need to append `&#x` and then end your value with a `;`. Like so:

#### Dashboard.xaml

```xml
<Label
    x:Name="RefreshLabel"
    Text="&#xf0e2;"
    FontSize="18"
    FontFamily="FontAwesome" />
```

## Bonus: Make the icon tappable

I added this piece of the code to the constructor of my codebehind file to run code on a tap of the icon. The `x:Name` names my label above and makes it addressable in my codebehind.

#### Dashboard.xaml.cs

```csharp
var refresh = new TapGestureRecognizer();
refresh.Tapped += async (s, e) => await DoRefresh();
RefreshLabel.GestureRecognizers.Add(refresh);
```
