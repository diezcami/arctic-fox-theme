---
layout: post
title: "Daily Word (WidgetKit/SwiftUI)"
date: 2020-10-26
permalink: widgetkit-dailyword
tags: mobile-dev
---
<!-- ![1.png]({{site.url}}/assets/resources-widgetkit-dailyword/1.png) -->

> **Daily Word** is now on the [App Store](https://apps.apple.com/us/app/daily-word-language-widget/id1535573526) if you want to add a little language to your homescreen.  Its source can be found on [GitHub](https://github.com/joshspicer/widgetkit-daily-language).

WidgetKit has been very exciting for lots of mobile developers, and something I recently explored a bit.  The result of this exploration is "Daily Word" - a simple app that, every ~24-hours, shows you a new `(Italian|French|Japanese)` word right on your homescreen!  It's simple and helped me nail down the basics of WidgetKit (and SwiftUI, something else i'd been wanting to try).

Specifically the [`getTimeline()`](https://github.com/joshspicer/widgetkit-daily-language/blob/main/DailyWidget/DailyWidget.swift#L32-L51) function, which defines the earliest possible time you'd like the widget to refresh (the OS will decide when _actually_ to do that refresh).  You then pass that new timeline to the completion.  

```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        
    // Time of creation
    let now: Date = Date()
    
    // The earliest moment we'd be ok with the widget refreshing
    let calendar = Calendar.current
    let future = calendar.date(byAdding: .hour, value: 24, to: now)!
    
    let lang = LanguageFactory.Create(lang: language)
    let randWord = lang.getRandom()
    
    let entry = WordEntry(date: now, word: randWord, flag: lang.getFlag())
    let timeline = Timeline(entries: [entry], policy: .after(future))
    
    completion(timeline)
}
```

![img](https://github.com/joshspicer/widgetkit-daily-language/raw/main/img.png)

## Add a new Language

Want to see your favorite language on your homescreen!  Add a word list to my app with a PR!

Wordlists are embedded into the widget and can be added easily.

1. Add a unique enum for your newly [Supported Language](https://github.com/joshspicer/widgetkit-daily-italian/blob/main/DailyItalianWord/SupportedLanguages.swift).
2. Create a new `.swift` file to [/Languages](https://github.com/joshspicer/widgetkit-daily-italian/tree/main/DailyItalianWord/Languages) that conforms to the `LanguageBase` protocol.

### Example {{language}}.swift

```swift
class {{language}} : LanguageBase {

    var words: [Word] = [
        Word(native: "war", foreign: "guerra"),
        Word(native: "thing", foreign: "cosa"),
        Word(native: "street", foreign: "strada")
        ...
        ...
    ]       
        
    func getAll() -> [Word] {
        return words
    }
    
    func getRandom() -> Word {
        let number = Int.random(in: 0..<words.count)
        return words[number]
    }
    
    func getFlag() -> String {
        return "🇮🇹"
    }
}
```

3. Add your new class here in the [LanguageFactory.swift](https://github.com/joshspicer/widgetkit-daily-italian/blob/main/DailyItalianWord/Languages/LanguageFactory.swift).

Your language will be available in the picker! 

<br>
----

Get Daily Word for yourself on the [**App Store**](https://apps.apple.com/us/app/daily-word-language-widget/id1535573526) and check out its source on [**GitHub**](https://github.com/joshspicer/widgetkit-daily-language).
