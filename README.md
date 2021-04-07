# CustomToolTip

CustomToolTip is a Swift Package for macOS Cocoa applications that lets you add tool tips that can use any kind of  `NSView` for their content without having to subclass or wrap your existing views.  That means it can be easily incorporated into an existing project.

Adding a tool tip is as easy as

```swift
myControl.customToolTip = myCustomTipContentView
```
where `myControl`, is the view you want to add a custom tool tip too, and  `myCustomTipContentView` is any `NSView` you like.

You can specify the margins between your custom tool tip content view, and the tool tip's window frame:

```swift
myControl.customToolTipMargins = CGSize(width: 5, height: 5)
```

By default CustomToolTip uses the current system window background color for the tool tip's background, but you can use any color you like:

```swift
myControl.customToolTipBackgroundColor = NSColor.blue
```
