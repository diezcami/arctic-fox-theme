---
layout: post
title: "JSX Comment Bug"
date: 2018-07-21
permalink: comments-count-bug
---

I was seeing this error recently while configuring a feature in my React Native application.
This bug caused a hard crash on Android (with no logged details), but just a warning on iOS.
```
07-21 15:59:09.778 29721 29753 W ReactNativeJS: Warning: Failed prop type: Invalid prop `children` of type `array` supplied to `ApolloProvider`, expected a single ReactElement.
07-21 15:59:09.778 29721 29753 W ReactNativeJS:     in ApolloProvider (at App.js:199)
07-21 15:59:09.778 29721 29753 W ReactNativeJS:     in App (at renderApplication.js:33)
07-21 15:59:09.778 29721 29753 W ReactNativeJS:     in RCTView (at View.js:60)
07-21 15:59:09.778 29721 29753 W ReactNativeJS:     in View (at AppContainer.js:102)
07-21 15:59:09.778 29721 29753 W ReactNativeJS:     in RCTView (at View.js:60)
07-21 15:59:09.778 29721 29753 W ReactNativeJS:     in View (at AppContainer.js:122)
07-21 15:59:09.778 29721 29753 W ReactNativeJS:     in AppContainer (at renderApplication.js:32)
07-21 15:59:10.103 29721 29721 D ReactNative: CatalystInstanceImpl.destroy() start
07-21 15:59:10.254 29721 29739 D ReactNative: CatalystInstanceImpl.destroy() end
```
Here was the trouble code. I saw that indeed, only one ReactElement should be doing anything.
```
return (
  <ApolloProvider client={client}>
    <Provider store={store}>
      <PersistGate persistor={persistor}>
        <AppWithNavigationAndQuery />
      </PersistGate>
    </Provider>
  {/* <PushNotifsConfig store={store}/> */}
  </ApolloProvider>
);
```
I discounted the commented out code, because it was commented out!
React Native (on Android), however, still saw this as valid JSX, causing the crash.
```
return (
  <ApolloProvider client={client}>
    <Provider store={store}>
      <PersistGate persistor={persistor}>
        <AppWithNavigationAndQuery />
      </PersistGate>
    </Provider>
  </ApolloProvider>
);
```
Of course, removing the commented out line solved my problem.  I'm sure most people will realize this immediately. For those who don't,
hopefully you find this page when googling for answers.
