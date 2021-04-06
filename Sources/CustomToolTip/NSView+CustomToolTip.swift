import AppKit
import SwizzleHelper

fileprivate func trace(
    _ message: @autoclosure () -> String = "",
    function: StaticString = #function,
    file: StaticString = #fileID,
    line: UInt = #line)
{
    #if DEBUG
    print("\(file): \(line): \(function): \(message())")
    #endif
}

// -------------------------------------
/*
 Convenice extension for updating a tracking area's `rect` property.
 */
fileprivate extension NSTrackingArea
{
    func updateRect(with newRect: NSRect) -> NSTrackingArea
    {
        return NSTrackingArea(
            rect: newRect,
            options: options,
            owner: owner,
            userInfo: nil
        )
    }
}

// -------------------------------------
/**
 Data structure to hold information used for holding the tool tip and for
 controlling when to show or hide it.
 */
fileprivate struct ToolTipControl
{
    /**
     `Date` when mouse was last moved within the tracking area.  Should be
     `nil` when the mouse is not in the tracking area.
     */
    var mouseEntered: Date?
    
    /// View to which the custom tool tip is attached
    weak var onwerView: NSView?
    
    /// The content view of the tool tip
    var toolTipView: NSView?
    
    /// `true` when the tool tip is currently displayed.  `false` otherwise.
    var isVisible: Bool = false
    
    /**
     The tool tip's window.  Should be `nil` when the tool tip is not being
     shown.
     */
    var toolTipWindow: NSWindow? = nil
    
    /**
     The tool tip's window margins.
     
     The tool tip's window will sized and the tool tip view positioned in it so that there is
     `toolTipMargins.width` between the left and right edges of the tool tip's view frame and the
     corresponding edges of the tool tip window, and `toolTipMargins.height` space between the top
     and bottom edges of the tool tip's view frame and the corresponding edges of the tool tip window.
     */
    var toolTipMargins: CGSize = CGSize(width: 5, height: 5)
    
    init(
        mouseEntered: Date? = nil,
        hostView: NSView,
        toolTipView: NSView? = nil)
    {
        self.mouseEntered = mouseEntered
        self.onwerView = hostView
        self.toolTipView = toolTipView
    }
}

// -------------------------------------
/**
 Data structure for holding `ToolTipControl` instances.  Since we only need
 one collection of them for the application, all its methods and properties
 are `static`.
 */
fileprivate struct ToolTipControls
{
    private static var controlsLock = os_unfair_lock()
    private static var controls: [ToolTipControl] = []
    
    // -------------------------------------
    static func getControl(for hostView: NSView) -> ToolTipControl? {
        withLock { return controls.first { $0.onwerView === hostView } }
    }
    
    // -------------------------------------
    static func setControl(for hostView: NSView, to control: ToolTipControl)
    {
        withLock
        {
            if let i = index(for: hostView) { controls[i] = control }
            else { controls.append(control) }
        }
    }
    
    // -------------------------------------
    static func removeControl(for hostView: NSView)
    {
        withLock
        {
            controls.removeAll {
                $0.onwerView == nil || $0.onwerView === hostView
            }
        }
    }
    
    // -------------------------------------
    private static func index(for hostView: NSView) -> Int? {
        controls.firstIndex { $0.onwerView == hostView }
    }
    
    // -------------------------------------
    private static func withLock<R>(_ block: () -> R) -> R
    {
        os_unfair_lock_lock(&controlsLock)
        defer { os_unfair_lock_unlock(&controlsLock) }
        
        return block()
    }
    
    // -------------------------------------
    private init() { } // prevent instances
}

fileprivate let bundleID = Bundle.main.bundleIdentifier ?? "com.CustomToolTips"
fileprivate let toolTipKeyTag = bundleID + "CustomToolTips"
fileprivate let customToolTipTag = [toolTipKeyTag: true]
fileprivate let dispatchQueue = DispatchQueue(
    label: toolTipKeyTag,
    qos: .background
)

// MARK:- NSView extension
// -------------------------------------
public extension NSView
{
    // -------------------------------------
    /**
     Adds a custom tool tip to the receiver.  If set to `nil`, the custom tool
     tip is removed.
     
     This view's `frame.size` will determine the size of the tool tip window
     */
    var customToolTip: NSView?
    {
        get { toolTipControl?.toolTipView }
        set
        {
            Self.initializeCustomToolTips()

            if let newValue = newValue
            {
                addCustomToolTipTrackingArea()
                var current = toolTipControl ?? ToolTipControl(hostView: self)
                current.toolTipView = newValue
                toolTipControl = current
            }
            else { toolTipControl = nil }
        }
    }
    
    // -------------------------------------
    /**
     Get/Set the margins for the tool tip's content within the tool tip window.
     */
    var customToolTipMargins: CGSize
    {
        get
        {
            toolTipControl?.toolTipMargins
                ?? CustomToolTipWindow.defaultMargins
        }
        set
        {
            var control = toolTipControl ?? ToolTipControl(hostView: self)
            control.toolTipMargins = newValue
            toolTipControl = control
        }
    }
    
    
    // -------------------------------------
    /**
     Gets/sets the `ToolTipControl` instance associated with the receiving view
     */
    fileprivate var toolTipControl: ToolTipControl?
    {
        get { ToolTipControls.getControl(for: self) }
        
        set
        {
            if let newValue = newValue {
                ToolTipControls.setControl(for: self, to: newValue)
            }
            else { ToolTipControls.removeControl(for: self) }
        }
    }
    
    // MARK:- Showing and Hiding Tool Tip
    // -------------------------------------
    /**
     Controls how many seconds the mouse must be motionless within the tracking
     area in order to show the tool tip.
     */
    private var customToolTipDelay: TimeInterval { 1 /* seconds */ }
    
    // -------------------------------------
    /**
     Displays the tool tip now.
     */
    private func showToolTip()
    {
        guard var control = toolTipControl else { return }
        defer
        {
            control.mouseEntered = Date.distantPast
            toolTipControl = control
        }
        
        guard let toolTipView = control.toolTipView else
        {
            control.isVisible = false
            return
        }
        
        if !control.isVisible
        {
            control.isVisible = true
            control.toolTipWindow = CustomToolTipWindow.makeAndShow(
                toolTipView: toolTipView,
                for: self,
                margins: control.toolTipMargins
            )
        }
    }
    
    // -------------------------------------
    /**
     Hides the tool tip now.
     */
    private func hideToolTip(exitTracking: Bool)
    {
        guard var control = toolTipControl else { return }
        
        control.mouseEntered = exitTracking ? nil : Date()
        control.isVisible = false
        let window = control.toolTipWindow
        
        control.toolTipWindow = nil
        window?.orderOut(self)
        control.toolTipWindow = nil
        
        toolTipControl = control
    }
    
    // -------------------------------------
    /**
     Schedules to potentially show the tool tip after `delay` seconds.
     
     The tool tip is not *necessarily* shown as a result of calling this method,
     but rather this method begins a sequence of chained asynchronous calls that
     determine whether or not to display the tool tip based on whether the tool
     tip is already visible, and how long it's been since the mouse was moved
     withn the tracking area.
     
     - Parameters:
        - delay: Number of seconds to wait until determining whether or not to
            display the tool tip
        - mouseEntered: Set to `true` when calling from `mouseEntered`,
            otherwise set to `false`
     */
    private func scheduleShowToolTip(delay: TimeInterval, mouseEntered: Bool)
    {
        guard var control = toolTipControl else { return }
        
        if mouseEntered
        {
            control.mouseEntered = Date()
            toolTipControl = control
        }

        let asyncDelay: DispatchTimeInterval = .milliseconds(Int(delay * 1000))
        dispatchQueue.asyncAfter(deadline: .now() + asyncDelay) {
            [weak self] in self?.scheduledShowToolTip()
        }
    }
    
    // -------------------------------------
    /**
     Display the tool tip now, *if* the mouse is in the tracking area and has
     not moved for at least `customToolTipDelay` seconds.  Otherwise, schedule
     to check again after a short delay.
     */
    private func scheduledShowToolTip()
    {
        let repeatDelay: TimeInterval = 0.1
        /*
         control.mouseEntered is set to nil when exiting the tracking area,
         so this guard terminates the async chain
         */
        guard let control = self.toolTipControl,
              let mouseEntered = control.mouseEntered
        else { return }
        
        if control.isVisible {
            scheduleShowToolTip(delay: repeatDelay, mouseEntered: false)
        }
        else if Date().timeIntervalSince(mouseEntered) >= customToolTipDelay
        {
            DispatchQueue.main.async
            { [weak self] in
                if let self = self
                {
                    self.showToolTip()
                    self.scheduleShowToolTip(
                        delay: repeatDelay,
                        mouseEntered: false
                    )
                }
            }
        }
        else { scheduleShowToolTip(delay: repeatDelay, mouseEntered: false) }
    }

    // MARK:- Tracking Area maintenance
    // -------------------------------------
    /**
     Adds a tracking area encompassing the receiver's bounds that will be used
     for tracking the mouse for determining when to show the tool tip.  If a
     tacking area already exists for the receiver, it is removed before the
     new tracking area is set. This method should only be called when a new
     tool tip is attached to the receiver.
     */
    private func addCustomToolTipTrackingArea()
    {
        if let ta = trackingAreaForCustomToolTip {
            removeTrackingArea(ta)
        }
        addTrackingArea(
            NSTrackingArea(
                rect: self.bounds,
                options:
                    [.activeInActiveApp, .mouseMoved, .mouseEnteredAndExited],
                owner: self,
                userInfo: customToolTipTag
            )
        )
    }
    
    // -------------------------------------
    /**
     Returns the custom tool tip tracking area for the receiver.
     */
    private var trackingAreaForCustomToolTip: NSTrackingArea?
    {
        trackingAreas.first {
            $0.owner === self && $0.userInfo?[toolTipKeyTag] != nil
        }
    }
    
    // MARK:- Swizzled Methods
    // -------------------------------------
    /**
     Updates the custom tooltip tracking aread when `updateTrackingAreas` is
     called.
     */
    @objc private func updateTrackingAreas_CustomToolTip()
    {
        if let ta = trackingAreaForCustomToolTip
        {
            removeTrackingArea(ta)
            addTrackingArea(ta.updateRect(with: self.bounds))
        }
        else { addCustomToolTipTrackingArea() }
        
        callReplacedMethod(for: #selector(self.updateTrackingAreas))
    }

    // -------------------------------------
    /**
     Schedules potentially showing the tool tip when the `mouseEntered` is
     called.
     */
    @objc private func mouseEntered_CustomToolTip(with event: NSEvent)
    {
        scheduleShowToolTip(delay: customToolTipDelay, mouseEntered: true)
        
        callReplacedEventMethod(
            for: #selector(self.mouseEntered(with:)),
            with: event
        )
    }
    
    // -------------------------------------
    /**
     Hides the tool tip if it's visible when `mouseExited` is called, cancelling
     further `async` chaining that checks to show it.
     */
    @objc private func mouseExited_CustomToolTip(with event: NSEvent)
    {
        hideToolTip(exitTracking: true)

        callReplacedEventMethod(
            for: #selector(self.mouseExited(with:)),
            with: event
        )
    }
    
    // -------------------------------------
    /**
     Hides the tool tip if it's visible when `mousedMoved` is called, and
     resets the time for it to be displayed again.
     */
    @objc private func mouseMoved_CustomToolTip(with event: NSEvent)
    {
        hideToolTip(exitTracking: false)
        
        callReplacedEventMethod(
            for: #selector(self.mouseMoved(with:)),
            with: event
        )
    }
        
    // MARK:- Swizzle initialization
    // -------------------------------------
    /**
     Swizzle methods if they have not already been swizzed for the current
     `NSView` subclass.
     */
    static func initializeCustomToolTips() {
        if !isSwizzled { swizzleCustomToolTipMethods() }
    }
    
    // -------------------------------------
    /**
     `true` if the current `NSView` subclass has already been swizzled;
     otherwise, `false`
     */
    private static var isSwizzled: Bool
    {
        return nil != Self.implementation(
            for: #selector(self.mouseMoved(with:))
        )
    }
    
    // -------------------------------------
    /**
     Replace the implementatons of certain methods in the current subclass of
     `NSView` with custom implementations to implement custom tool tips.
     */
    private static func swizzleCustomToolTipMethods()
    {
        replaceMethod(
            #selector(self.updateTrackingAreas),
            with: #selector(self.updateTrackingAreas_CustomToolTip)
        )
        replaceMethod(
            #selector(self.mouseEntered(with:)),
            with: #selector(self.mouseEntered_CustomToolTip(with:))
        )
        replaceMethod(
            #selector(self.mouseExited(with:)),
            with: #selector(self.mouseExited_CustomToolTip(with:))
        )
        replaceMethod(
            #selector(self.mouseMoved(with:)),
            with: #selector(self.mouseMoved_CustomToolTip(with:))
        )
    }
 }

