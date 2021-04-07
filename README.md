# CustomToolTip

CustomToolTip is a Swift Package for macOS Cocoa applications that lets you add tool tips that can use any kind of  `NSView` for their content without having to subclass or wrap your existing views.  That means it can be easily incorporated into an existing project.

![Screenshot]((./Images/ScreenShot.png)

## Project Set Up

- Step 1: Add [https://github.com/chipjarred/CustomToolTip.git](https://github.com/chipjarred/CustomToolTip.git) as a Swift Package dependency to your project in Xcode.
- Step 2: *There is no step 2!*

CustomToolTip provides an extension on `NSView` that handles the rest.  You can focus on creating your tool tip content and attach it to your views with the `customToolTip` property that the extension adds to `NSView`.

You don't need to subclass anything. You don't need to nest views in a special tool tip view.  You don't even need to change anything in storyboards.  

## How to add custom tool tips

Adding a tool tip is as easy as

```swift
myControl.customToolTip = myCustomTipContentView
```
where `myControl`, is the view to which you want to attach a custom tool tip, and  `myCustomTipContentView` is any `NSView` you want to use as the tool tip's content.

The only requirement is that your tool tip view's frame size should be properly set before adding it, as the tool tip will adjust it's size according to your content view's frame.

You can specify the margins between your custom tool tip content view, and the tool tip's window frame:

```swift
myControl.customToolTipMargins = CGSize(width: 5, height: 5)
```

By default CustomToolTip uses the current system window background color for the tool tip's background, but you can use any color you like:

```swift
myControl.customToolTipBackgroundColor = NSColor.blue
```
