---
layout: post
title: "Paying Attention to Android (React Native)"
date: 2018-08-27
permalink: react-native-android
tags: react-native parade
---

> Edit: Our Android release is out NOW on Google Play! Find it [here](https://play.google.com/store/apps/details?id=com.parade).

<h2>Intro</h2>
We focused on iOS for the initial development of Parade. Here are a small set of the things I learned had to be done differently when "porting" to Android.

![notebook]({{site.url}}/assets/resources-android-support/notebook.png)

<h2>Yoga Bug</h2>
When prettier adds a stray semicolon automatically, iOS doesn't care but Android crashes..... I've seen this
soo much.
![yoga_bug]({{site.url}}/assets/resources-android-support/yoga-bug.png)

<h2>Text Inputs look Ugly</h2>

If you designed text inputs on iOS and are happy with them, you can make it look similar by adding `underlineColorAndroid`.
{% highlight javascript %}
<TextInput
value={value}
autoCapitalize={'none'}
onChangeText={(value) => onChange(value)}
style={[styles.textInput, style]}
placeholder={placeholder}
placeholderTextColor={COLORS.PLACEHOLDER_GRAY}
underlineColorAndroid="transparent" <------- Add me!
/>
{% endhighlight %}

<h2>Hardware Back Button</h2>
I love Android's "hardware" (it's on the screen of my pixel, but ya know what I mean) back button. iOS doesn't have this,
so obviously it was not working as intended on Android. `React-navigation`'s docs said that it should work out of the box,
but that didn't seem to be the case. Perhaps it's because we're utilizing 'modal' views (because of the animation).

I used [BackHandler](https://facebook.github.io/react-native/docs/backhandler) to detect the press with a lifecycle method
listener and redux to communicate with react-navigation.

```javascript
componentDidMount() {
  BackHandler.addEventListener('hardwareBackPress', this.handleBackPress);
}

componentWillUnmount() {
  BackHandler.removeEventListener('hardwareBackPress', this.handleBackPress);
}

handleBackPress = () => {
  store.dispatch({ type: 'Navigation/BACK' });
  return true;
}
```

<h2>Fix Universal (HTTP) Linking</h2>
 Check out the dedicated post on it at [Android React Native Linking]({{site.url}}/parade-linking-android).

 <h2>Software Keyboard Pushing Absolute Elements</h2>
 On iOS elements styled with 'absolute' don't get pushed around - and we used that in our designs.

![keyboard-aware-before]({{site.url}}/assets/resources-android-support/keyboard-aware-before.png)

`android:windowSoftInputMode="adjustPan"` (I had 'adjustResize' there by default.)
I use react-native-keyboard-aware-scroll-view to do keyboard padding for us, since
'adjustResize' is just not smart enough. Check out their [keyboard-aware's android section](https://github.com/APSL/react-native-keyboard-aware-scroll-view#android-support).

![keyboard-aware-after]({{site.url}}/assets/resources-android-support/keyboard-aware-after.png)

<h2>Manifest Updates</h2>

I configured a lot of things in Xcode that I needed to re-do on Android.

<h3>App Icons</h3>
I used [this site](https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html) to create both
rectangular and circular app icons. I then declared both in the manifest.
```xml
<application
  android:name=".MainApplication"
  android:label="@string/app_name"
  android:icon="@mipmap/ic_launcher"   <----------------- There by default
  android:roundIcon="@mipmap/ic_launcher_round" <----------------- Added this
  ...
  ...
```
<h3>Device orientation</h3>
Simple one. In my main MainActivity...
```xml
<activity
  android:name=".MainActivity"
  android:label="@string/app_name"
  android:launchMode="singleTask"
  android:screenOrientation="portrait" <----------------- Whatever you want
  android:configChanges="keyboard|keyboardHidden|orientation|screenSize"
  android:windowSoftInputMode="adjustResize">
    ....
    ....
```

<h2>Must meet API requirements for new apps</h2>

> Google Play will require that new apps target at least Android 8.0 (API level 26) from August 1, 2018...
> Every new Android version introduces changes that bring significant security and performance improvements – and enhance the user experience of Android overall. > Some of these changes only apply to apps that explicitly declare support through their targetSdkVersion manifest attribute (also known as the target API level).

In `<RN project>/android/app/build.gradle`.

```java
...
android {
    compileSdkVersion 26  <----- Bump me
    buildToolsVersion "26.0.2" <---- Me too

    defaultConfig {
        applicationId "com.parade"
        minSdkVersion 16
        targetSdkVersion 26  <---- Yea same
        versionCode 1
        versionName "1.0"
        ndk {
            abiFilters "armeabi-v7a", "x86"
        }
    }
    signingConfigs {
    release {
        ...
```

<h2>deployment RN docs</h2>
Facebook has a really good guide on [creating your signed APK](https://facebook.github.io/react-native/docs/signed-apk-android.html), so i'll
just add in pieces of info I found important on deployment.

<h3>deployment keys on MacOS</h3>
I wasn't fond of keeping my app's cert password in plaintext, and neither was [Viktor Eriksson](https://pilloxa.gitlab.io/posts/safer-passwords-in-gradle/
). If you're running macOS I suggest storing your passwords in the OSX keychain like he did.

<h3>App Versioning</h3>
In your app's `build.gradle` you need to specify two parameters before uploading to Google Play.
```java
...
android {
    compileSdkVersion 26
    buildToolsVersion "26.0.2"

    defaultConfig {
        applicationId "com.parade"
        minSdkVersion 16
        targetSdkVersion 26
        versionCode 2 <--------------- Integer. Must be higher than previous upload.
        versionName "1.4" <----------- String. Customer-facing. I'm going to line this up with iOS release numbers.
        ndk {
            abiFilters "armeabi-v7a", "x86"
        }
    }
    ....

```

<h3>Uploading APK</h3>
Once you release internally, it's going to say "Pending Publication" up top for a while. It's not explained well,
but you just need to wait that out and then it will be available to your internal team. It took mine close to 30 minutes to
actually publish.

![published]({{site.url}}/assets/resources-android-support/published.png)

Soooo many devices to deal with now.

![supported-devices]({{site.url}}/assets/resources-android-support/supported-devices.png)

<h3>Internal Testing</h3>
For some reason you need to add all your internal tester's emails on the web console, but then it doesn't
automatically send out the invite link via email. After your app publishes, a new  `opt-in link` will be available on your release
which you should manually email to all the people you added above (?).
```
