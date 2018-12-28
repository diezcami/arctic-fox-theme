---
layout: post
title: "iOS Universal Linking with React Native"
date: 2018-08-02
permalink: parade-linking
---

[Universal linking](https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html) was
a feature I was really excited to implement in [Parade](https://parade.events). I thought it would be more difficult, but react-native and Apple
make it wicked simple to both implement and configure.
<br><br>
Universal linking is what lets a standard HTTP url (`https://parade.events/e/123`) trigger an installed mobile app to "jump" straight to the
specified content. The URI is a deep link into a part of the app, while at the same time doubling as a valid HTTP link.
Imagine `'123'` refers to a specific event within Parade. I can then text/share this link to friends, and they will be brought directly
to event `'123'` in-app - really cool!

![linking-gif]({{site.url}}/assets/resources-parade-linking/linking.gif)

The [React Native docs](https://facebook.github.io/react-native/docs/linking) explain where the Linking libraries are and where to link them. Super straight-forward, took 5 minutes. Make sure to also link the optional "Universal Linking" stuff.

In Xcode I had to register my domain with the app. This can be done in your app's "Capabilities" tab. Make sure to start your
domain with `applinks:`

![xcode]({{site.url}}/assets/resources-parade-linking/xcode.png)


In the webroot of the `parade.events` website, I then added this json object in a file
called `apple-app-site-association`. This is to prove to actually own the domain, I guess. You can use an asterisk to
specify wildcard.
```
{
    "applinks": {
        "apps": [],
        "details": [
            {
                "appID": "V3AVXCHMVA.com.paradeevents.parade",
                "paths": [ "/event/*","e/*","/org/*","o/","/user/*"]
            }
        ]
    }
}
```

Within my React Native app, I import `Linking`, and then listen for URLs. I parse
these urls and dispatch actions based on the structure of the URL.

```
componentDidMount() {
  Linking.addEventListener('url', this._handleOpenURL);
  Linking.getInitialURL().then(url => {
    if (url) {
      this._handleOpenURL({ url });
    }
  });
}

componentWillUnmount() {
  Linking.removeEventListener('url', this._handleOpenURL);
}

_handleOpenURL(evt) {
  {..truncated...}

  const method = splitPath[1];
  const id = splitPath[2];

  switch (method) {
    case 'event':
    case 'e':
      store.dispatch({
        type: 'NAVIGATE',
        routeName: 'EventsDetails',
        params: { id },
      });
      break;
    case 'org':
    case 'o':
      store.dispatch({
        type: 'NAVIGATE',
        routeName: 'OrganizationProfile',
        params: id,
      });
      break;
      // <ADD MORE CASES HERE>
    default:
      // ERROR
  }
}
```


<h2>Test Links!</h2>

Obviously none of these will work if you don't have Parade installed! These links are helping me test a few
finer details (valid URLs but invalid IDs, etc...).

- [https://parade.events/event/VALID_EVENT_ID](https://parade.events/event/5b63bf5ff2d3e8766a0ddda9)
- [https://parade.events/e/VALID_EVENT_ID](https://parade.events/e/5b63bf5ff2d3e8766a0ddda9)

- [https://parade.events/org/VALID_ORG_ID](https://parade.events/org/5b525a5d516db7f3057035f1)
- [https://parade.events/o/VALID_ORG_ID](https://parade.events/o/5b525a5d516db7f3057035f1)

- [https://parade.events/notAValidPath/...](https://parade.events/notAValidPath/5woiafjdfjdkfljdslk)
- [https://parade.events/org/INVALID_ORG_ID](https://parade.events/org/fakefakefake)
