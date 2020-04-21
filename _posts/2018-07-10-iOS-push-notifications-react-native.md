---
layout: post
title: Push Notifications in React Native & iOS (Client & Server Setup!)
date: 2018-07-12
permalink: parade-push-notifications
favorite: "true"
tags: mobile-dev react-native
---

> There's lots of guides online about push notification setup for a React Native iOS app...and that's the problem!
> This guide is the combination of the numerous resources found online into **one** place, as well as commentary from
> me in places where things went wrong.

<h2>Intro</h2>
<h3>Goal</h3>
We have been developing [Parade](https://parade.events/) for a few months now - and this morning I decided
I wanted to implement push notifications - seems important for an events app, right?
<br><br>
In this guide we're going to be configuring our client to register with Apple's Push Notification Service (APN), register with
*our* application server, and receive both local and remote notifications. We will be configuring our own application server to dispatch notifications to
specific users of our service on command.
<h3>What are we working with?</h3>
Parade is a React Native application that we've been writing and then deploying on TestFlight throughout development. We run
our own node/graphQL server out on AWS that serves data to and from our app.
<br><br>
While there are services that exist to handle the server portion of this tutorial (Firebase, Amazon SNS, etc...). I wanted to make my own for two reasons:
<br><br>
One, I already feel reliant on multiple services, and we haven't even released the app yet! This is a low budget project, and tacking on more services for a little
bit of convenience is going to add up fast.
<br><br>
Second, I was curious *how* to do it.  I now realize it was much more complicated than I expected...but if you're reading this, that
means I got through it and (hopefully) condensed it down into simple(r) steps below.

<h2>Prereqs</h2>
- A Valid Apple Developer Account
- A React Native (partially) written and deployable to TestFlight
- A Mac (xcode)
- A Physical iPhone/iPad/iPod to test on

While Parade will eventually be released on both iOS and Android, I decided for this article to focus exclusively on iOS. I did, however, consider that i'll eventually
need to tack on Android, so most of what I write in this guide has that eventual addition in mind.
<br><br>
If you're not using React Native/Redux/GraphQL/Mongo this guide may still be for you, just keep in mind that's the tech stack i'm working with.

<h2>Local Notifications Client-side</h2>

Lets start slow and first focus on setting up local push notifications. These are notifications that are generated
from the client itself, and not from a remote server. Doesn't seem too useful in the long run, but definitely a good
place for us to start.

<h3>Enable in Xcode</h3>

Enable the push notification capability for your project in XCode. For React Native, your
`.xcodeproj` file can be found in the `ios/` folder of your project.
<br><br>
Not sure if this is necessary for local notifications to be pushed, but we'll definitely
need it later - so lets just do it now.

![xcode-1]({{site.url}}/assets/resources-push-notifications/xcode-1.png)

<h3>react-native-push-notification</h3>

I'm going to be using a package called [react-native-push-notification](https://github.com/zo0r/react-native-push-notification),
which wraps both the Android and iOS APIs that react-native provides. This package requires manual setup for both platform. For now,
i'm only going to work through the iOS portion (I'll work through the Android side in a different post - I promise!).
<br><br>
To start, add the package to your react-native project with `yarn add react-native-push-notification`.
<br><br>
...and link with `react-native link`.

<h3>iOS Manual Install</h3>

I followed the official React Native docs to [link push notifications](https://facebook.github.io/react-native/docs/pushnotificationios.html). This involves opening up xcode and linking some react-native libraries. Follow this guide - it's very detailed, and very important!
<br><br>
[This page](https://facebook.github.io/react-native/docs/linking-libraries-ios#manual-linking) goes into detail of how to manually link libraries.
I completed all three steps, and that seemed to work.

<h3>Testing Local Notification</h3>

In my App's main file `App.js`, I then imported `react-native-push-notification` and
wrote the following code in the `componentDidMount` lifecycle function.

{% highlight javascript %}
componentDidMount() {
//Push Notifications
PushNotification.configure({
// (required) Called when a remote or local notification is opened or received
onNotification: function(notification) {
console.log('NOTIFICATION:', notification);
// process the notification
},
onRegister: function(token) {
// We will use this later!
},
requestPermissions: true, // This is the default value. We'll be modifying this later!
//....check the docs for more options.....
});
}
{% endhighlight %}

Next time I launched the app, I was prompted to allow push notifications - looking good!
<br><br>
![allow-push-notifs]({{site.url}}/assets/resources-push-notifications/allow-push-notifs.png)

Lets now send a local notification. We'll trigger the notification via a button in the _secret_ Parade
debug menu. I'll put a five second delay on the button so we have time to leave the app and see the notification come through.

Note: To see the notification, the app needs to be in the background. Also note that,
while local notifications **will** work in the simulator, remote notifications we send later **will not**.

{% highlight javascript %}
launchTestNotification() {
PushNotification.localNotificationSchedule({
title: 'PARADE PARADE',
message: 'Amazing Parade Notification',
date: new Date(Date.now() + 5 \* 1000),
});
}
{% endhighlight %}

I tied this function to a button...

![test-local-1]({{site.url}}/assets/resources-push-notifications/test-local-1.png)

...and quickly exited the app.

![test-local-2]({{site.url}}/assets/resources-push-notifications/test-local-2.png)

<h2>Apple Developer Config</h2>

We will now visit the Apple dev site to mark our app as one that will be utilizing the Apple push notification (APN) service.
<br><br>
First, make sure you've followed the step above where we enabled push notifications in our Xcode project! This should trigger some
changes on the Apple developer site.
<br><br>
Next, login to your dev account at `https://developer.apple.com/account/ios/identifier/bundle`.
You should see that push notifications are now configurable.

![dev-site-1]({{site.url}}/assets/resources-push-notifications/dev-site-1.png)

Follow these steps from Apple to create a certificate to communicate with APN for your app ID.
<br><br>
(**Future Josh Note**: I ended up using APN Keys instead of these certificates. I still, however, think this step is necessary to
simply turn on the APN service. Check the later sections for how to get that key.)

1. In Certificates, Identifiers & Profiles, enable the Push Notifications service.
2. Under Development SSL Certificate or Production SSL Certificate, click Create Certificate.
3. Follow the instructions to create a certificate signing request on your Mac, and click Continue.
4. Click Choose File.
5. In the dialog that appears, select the certificate request file (a file with a .certSigningRequest file extension), then click Choose.
6. Click Continue.
7. Click Download.
   The certificate file (a file with a .cer file extension) appears in your Downloads folder.

Nice, now its green - and we have the cert saved to our Mac's keychain.

![dev-site-2]({{site.url}}/assets/resources-push-notifications/dev-site-2.png)

![keychain-access-1]({{site.url}}/assets/resources-push-notifications/keychain-access-1.png)

<h2>Requesting Token from APN in React Native</h2>

Lets move back to our React Native project now. We have everything set up to receive
push notification tokens from APN.
<br><br>
Very simply, the push notification service acts as an intermediary between client devices, and the production server a
developer controls. Client apps register with the APN service, and developers can then tell APN to send a push to those devices that
are registered.
<br><br>
I found this image from a post from user [Karan Alangat](https://stackoverflow.com/questions/17262511/how-do-ios-push-notifications-work)
on stackOverflow that helped me understand the flow.
<br><br>
![stackOverflow photo](https://i.stack.imgur.com/6HtsK.jpg)

As you can see, requesting APN tokens are retrieved via a call to the OS itself. This is how push notifications are sent to a device without every
single application on the device listening at the same time.

<h3>Testing onRegister()</h3>

The `react-native-push-notification` API provides a function `onRegister()` that is called whenever our app registers with the APN servers. Lets see if we can get
Apple to send us a token.
<br><br>
To test this functionality, I pointed my test device at a local test server, and placed an `Alert` in the body of the `onRegister` callback. There
are two fields in the return value `token` and `os`, so I very quickly capture those and print as a proof of concept.
<br><br>
In my case, I also capture the token and store it in our redux state so that I can utilize that value later.
<br><br>
_Note: you will need a real device to communicate with APN, NOT the simulator_.

{% highlight javascript %}
onRegister: function(token) {
console.log('TOKEN:', token);
tokenToken = token.token
tokenOS = token.os
Alert.alert(
'Push Notifications Registered',
tokenToken + "" + tokenOS,
[
{
text: 'Cancel',
onPress: () => {
console.log('cancel onRegister Alert');
},
style: 'cancel',
},
],
{ cancelable: true },
);

// Store the token.
store.dispatch({
type: 'STORE_THE_IOS_NOTIF_TOKEN',
iOSPushNotifToken: tokenToken,
});
},
{% endhighlight %}

Each time I fully quit and launch the app I see this. Our app is now officially communicating with APN!

![push-registered]({{site.url}}/assets/resources-push-notifications/push-registered.png)

<h3>Storing tokens remotely</h3>

This part of the article is going to start blurring the lines between client and server, and will
also be very dependent on how your app is structured.
<br><br>
This token needs to be communicated to our own backend server and associated with this user.
As we saw in the last section, each time `onRegister()` is called, the received token is stored in state temporarily.
<br><br>
Since knowing the identity of the user is important, we don't immidiately want to tell our server about every token we receive.
We need to first ensure that the user is logged in. With that in mind, lets go back to our PushNotification.configure() and set
`requestPermissions` to `false`.
<br><br>
We now have to initiate requesting permissions manually. We do this by calling `PushNotifications.requestPermissions()` in the appropriate place.
More info on this can be found within the library's documentation.
<br><br>
Parade uses GraphQL, so I created a custom mutation that is called and mutates the current user's `iOSPushNotifToken` field in the database.
I placed the method in our User's Profile class with some conditions. The code will only run if we have a valid auth token and if we don't have a
push notification token cached.
<br><br>
One bug I did encounter: `componentDidMount` likes to get called twice, which causes `requestPermissions` to get called twice before it finishes. To avoid this,
I cached the request in a variable called `requestRunning`. If the promise hasn't been fulfilled yet, our variable will contain the promise and the first if case in `componentDidMount` will get tripped - halting execution.

{% highlight javascript %}
class UsersProfile extends React.Component {
constructor(props) {
super(props);
requestRunning = null;
}

componentDidMount() {
// Cache the state of this function so that `requestPermissions` doesn't run twice.
if (requestRunning) {
return;
}
const iOSPushNotifToken = _.get(this.props, 'iOSPushNotifToken');
const authToken = _.get(this.props, 'authToken');
if (authToken && !iOSPushNotifToken) {
// We have an AuthToken and don't have a push token.
// Ask Apple for one.
requestRunning = PushNotification.requestPermissions().then(() => {
requestRunning = false; //Allow this method to be called again.
});
}
}

componentDidUpdate(prevProps, prevState) {
const prevData = _.get(prevProps, 'iOSPushNotifToken');
const currData = _.get(this.props, 'iOSPushNotifToken');
const authToken = \_.get(this.props, 'authToken');

    if (jwt && prevData !== currData) {
      // The Notifcation Token has changed. Tell our server.
      this.props.pushTokenToServer(currData);
    }

}

{...truncated...}
{% endhighlight %}

I then made some quick modifications to our database schema to allow for a new field. In the end,
our goal was to get this value stored in a given user's database entry, like so.

![mongoEntry]({{site.url}}/assets/resources-push-notifications/mongoEntry.png)

<h2>Server setup</h2>

Great! We're now on to step 4 of the flow chart above. We have the iOS APN token saved on our server.
We now need to determine when something interesting happens to our user and utilize that `iOSPushNotifToken` to tell Apple to issue a Push notification.

<h3>Developer Notification Key</h3>

First things, first - another key! This one is issued by Apple, and is the key we need on our server to tell Apple we're authorized to send push notifications. Visit [this page](https://developer.apple.com/account/ios/authkey/) on the developer portal to create a key. You'll receive a `.p8` file and see your `Key ID` on screen. Keep both of these - we'll need them soon!

![create-key-1]({{site.url}}/assets/resources-push-notifications/create-key-1.png)

<h3>Yet another library</h3>
This stuff is complicated, so we're going to utilize a library called [node-pushnotifications](https://github.com/appfeel/node-pushnotifications) to make our lives easier.
This library issues push requests to the appropriate server (Apple, Google, etc...) for all the platforms (iOS, Android, etc...) we care about. This library even decides where to send the push to based on the device token you provide - that's pretty cool!
<br><br>
Get this running on your node server with `yarn add node-pushnotifications`.

<h3>node-pushnotifications configuration</h3>

Everything i'm going to do can be found in much greater detail over at [node-pushnotification's](https://github.com/appfeel/node-pushnotifications) README page.
I'm going to walkthrough how to get a barebones notification dispatch system set up on your application's server, and only for iOS (for now).
<br><br>
Some notes:
<br>

- The `topic` field in the data **must** be your package ID (for me it's `com.paradeevents.parade`). This was wicked annoying to debug as
  it wasn't clearly documented and the name makes no sense.
  <br><br>
- For some reason relative paths weren't working for my `key`. I used the **absolute** path to my `.p8` file and that worked. Weird.
  <br><br>
- You can find your [KeyID here](https://developer.apple.com/account/ios/authkey/).
  <br><br>
- You can find your [TeamID here](https://developer.apple.com/account/#/membership/).

{% highlight javascript %}
import PushNotifications from 'node-pushnotifications';

const settings = {
apn: {
token: {
key: '/Users/josh/Documents/parade/.../AuthKey.p8',
keyId: '<YOUR KEY ID>',
teamId: '<YOUR TEAM ID>',
},
production: false,
},
// more available
};
const push = new PushNotifications(settings);

const testRegID = <YOUR DEVICE>;

const data = {
title: 'Remote Push!', // Title of push notification.
topic: 'com.paradeevents.parade', // REQUIRED for iOS
};

push
.send(testRegID, data)
.then(results => console.log(results[0]))
.catch(err => console.log(err));
{% endhighlight %}

When I reload the server with this page in scope - success!

```
{ method: 'apn',
  success: 1,
  failure: 0,
  message: [] }
```

![success-remote-push]({{site.url}}/assets/resources-push-notifications/success-remote-push.png)

For additional testing I consolidated some of the variables into a simple function.

{% highlight javascript %}
const push = new PushNotifications(settings);

export function triggerPush(id, msg) {
const data = {
title: 'Parade Events 🐘', // REQUIRED for Android
topic: 'com.paradeevents.parade', // REQUIRED for iOS
body: msg || 'test push',
};

push
.send(id, data)
.then(results => console.log(results))
.catch(err => console.log(err));
}
{% endhighlight %}

...and imported this function into my `index.js`

{% highlight javascript %}
import { triggerPush } from './data/pushNotification';
{% endhighlight %}

I wrote a super simple REST endpoint that sends the message I write contained in a URL parameter.

{% highlight javascript %}
app.use('/testPush', function(req, res) {
triggerPush(
'<target device ID>',
req.query.msg
);
});
{% endhighlight %}

This sends a push to anyone that has a valid token stored in the database.

{% highlight javascript %}
//Sends a Push Notification to anyone in `UsersDb` that has a token in their `iOSPushNotifToken` field.
export function pushNotificationToEveryone(msg) {
UsersDb.find(
{ iOSPushNotifToken: { \$exists: true } },
{ iOSPushNotifToken: 1, \_id: 0 },
).then(out => pushNotificationToEveryoneHelper(out, msg));
}

// Helper for above function. Send out a for each target ID.
function pushNotificationToEveryoneHelper(out, msg) {
var cleaned = \_.map(out, function(x) {
return x.iOSPushNotifToken;
});

\_.forEach(cleaned, function(target) {
triggerPush(target, msg);
});
}
{% endhighlight %}

So `http://localhost:port/testPush?msg=testing123` results in...

![more-remote-push]({{site.url}}/assets/resources-push-notifications/more-remote-push.png)

<h2>Other issues (and my fixes)</h2>

<h3>Collisions</h3>

When Apple sends us an APN token, they don't know who is logged in, or even the concept of our app having users.
Therefore, if two users login on the same device, they will be given the same token from Apple.
In my database, this means multiple people are likely to have the same `iOSPushNotifToken`. Not good!
<br><br>
In this example, two accounts were used on a single device, and then both were logged out. Apple doesn't know we logged out,
and we didn't clear the tokens from our database, so this happens.

![collision-1]({{site.url}}/assets/resources-push-notifications/collision-1.png)

One solution is to clear the APN token from the user's identity on logout.

<h3>TestFlight == Production (??)</h3>

Small fix. When deploying to TestFlight, the `production` flag in our `node-pushnotifications` config must be set to `true`.
Also make sure to securely copy your key over to your hosting server (don't check it into git!).

{% highlight javascript %}
//{...truncated...}
const settings = {
apn: {
token: {
key: '/Users/josh/Documents/parade/.../AuthKey.p8',
keyId: '<YOUR KEY ID>',
teamId: '<YOUR TEAM ID>',
},
production: true, // was false!!!
},
};
const push = new PushNotifications(settings);

//{...truncated...}
{% endhighlight %}

<h2>Final Words</h2>
Push notifications are not quite as simple as I imagined! There's lots of moving pieces...and the fact that we ignored
Android the whole time definitely scares me... Now that it's set up, Parade definitely feels more complete!
<br><br>
Let me know if this helps, or if I made a terrible mistake somewhere!
