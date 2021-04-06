# CustomToolTip

CustomToolTip is a Swift Package for macOS Cocoa applications that lets you add tool tips that can use any kind of  `NSView` for their content without having to subclass or wrap your existing views.  That means it can be easily incorporated into an existing project.

Adding a tool tip is as easy as

```swift
myControl.customToolTip = myCustomTipContentView
```
where `myCustomTipContentView` is any `NSView` you like.
