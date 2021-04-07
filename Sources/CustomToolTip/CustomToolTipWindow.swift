import AppKit

public var defaultMargins: CGSize = CGSize(width: 5, height: 5)
public var defaultBackgroundColor: NSColor = .windowBackgroundColor

// MARK:- Custom Tool Tip Window
// -------------------------------------
/**
 Window for displaying custom tool tips.
 */
internal final class CustomToolTipWindow: NSWindow
{
    // -------------------------------------
    /**
     Makes a tool tip containing the view content specified by `toolTipView`,
     and displays it.
     
     The if `mouseLocation` is provided, the tool tip will be positioned
     relative to it; otherwise the tool tip is positioned relative to the
     `owner` view.
     
     - Parameters:
        - toolTipView: An `NSView` to render the tool tip contents.
        - owner: The `NSView` that owns the tool tip.  That is the view that
            the tool tip describes.
        - margins: `CGSize` specifying how much much space should be allowed
            between the `toolTipView`'s frame the tool tip window's frame.
            The `.width` property specifes both the left and right margins,
            and the `.height` property specifies the top and bottom margins.
            The total added width will `2 * margins.width` and the added height
            will be `2 * margins.height`.  If `nil`, a default margin is used.
        - backgroundColor: An `NSColor` specifying the background color for the
            tool tip window.  If `nil` the system default
            `NSColor.windowBackgroundColor` is used.
        - mouseLocation: The current mouse location in the `owner`'s *window*'s
            coordinates.  If provided the tool tip will be positioned relative
            to the mouse location.  If `nil`, the tool tip will be positioned
            relative to `owner`.
     
     - Returns: The `CustomToolTipWindow`, which is already being shown on
        return.
     */
    public static func makeAndShow(
        toolTipView: NSView,
        for owner: NSView,
        margins: CGSize = defaultMargins,
        backgroundColor: NSColor = defaultBackgroundColor,
        mouseLocation: CGPoint? = nil) -> CustomToolTipWindow
    {
        let window = CustomToolTipWindow(
            toolTipView: toolTipView,
            for: owner,
            margins: margins,
            backgroundColor: backgroundColor,
            mouseLocation: mouseLocation
        )
        window.orderFront(self)
        return window
    }
    
    // -------------------------------------
    public init(
        toolTipView: NSView,
        for toolTipOwner: NSView,
        margins: CGSize,
        backgroundColor: NSColor,
        mouseLocation: CGPoint?)
    {
        toolTipView.setFrameOrigin(.init(x: margins.width, y: margins.height))
        
        let tipFrame = toolTipView.frame
        
        let borderFrame = CGRect(
            origin: .zero,
            size: CGSize(
                width: tipFrame.width + 2 * margins.width,
                height: tipFrame.height + 2 * margins.height
            )
        )
        
        let border = BorderedView.init(frame: borderFrame)
        border.addSubview(toolTipView)
        
        super.init(
            contentRect: border.bounds,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.contentView = border
        self.contentView?.isHidden = false

        self.backgroundColor = backgroundColor
        
        if let mouseLoc = mouseLocation {
            reposition(relativeTo: mouseLoc, inWindowOf: toolTipOwner)
        }
        else { reposition(relativeTo: toolTipOwner) }
    }
    
    // -------------------------------------
    deinit { orderOut(nil) }
    
    // -------------------------------------
    /**
     Place the tool tip window's frame in a sensible place relative to the
     tool tip's owner view on the screen.
     
     If the current layout direction is left-to-right, the preferred location is
     below and shifted to the right relative to the owner.  If the layout
     direction is right-to-left, the preferred location is below and shifted to
     the left relative to the owner.
     
     The preferred location is overridden when any part of the tool tip would be
     drawn off of the screen.  For conflicts with horizontal edges, it is moved
     to be some "safety" distance within the screen bounds.  For conflicts with
     the bottom edge, the tool tip is positioned above the owning view.
     
     Non-flipped coordinates (y = 0 at bottom) are assumed.
     */
    private func reposition(relativeTo toolTipOwner: NSView)
    {
        guard let ownerWindow = toolTipOwner.window else { return }
        
        reposition(
            relativeTo:
                toolTipOwner.convert(
                    toolTipOwner.bounds,
                    to: nil
                ),
            in: ownerWindow,
            hOffset: toolTipOwner.frame.width / 2,
            vOffset: 0
        )
    }
    
    // -------------------------------------
    /**
     Place the tool tip window's frame in a sensible place relative to the
     mouse location on the screen.
     
     The preferred location is overridden when any part of the tool tip would be
     drawn off of the screen.  For conflicts with horizontal edges, it is moved
     to be some "safety" distance within the screen bounds.  For conflicts with
     the bottom edge, the tool tip is positioned above the owning view.
     
     Non-flipped coordinates (y = 0 at bottom) are assumed.
     */
    private func reposition(
        relativeTo mouseLocation: CGPoint,
        inWindowOf toolTipOwner: NSView)
    {
        guard let ownerWindow = toolTipOwner.window else { return }
        
        reposition(
            relativeTo: NSCursor.current.frame(for: mouseLocation),
            in: ownerWindow,
            hOffset: 0,
            vOffset: 0
        )
    }
    
    // -------------------------------------
    /**
     Reposition the tool tip window relative to the specified `rect`
    
     For conflicts with horizontal edges, the tool tip is moved horizontally to
     be some "safety" distance within the screen bounds.  For conflicts with
     the bottom edge, the tool tip is positioned above `rect` rather than below
     it.
     
     - Parameters:
        - rect: `CGRect` in the coordinates of the tool tip owning view's
            window.
        - ownerWindow: The window to which the tool tip owning view belongs
        - hOffset: The distance to horizontally offset the tool tip from
            `rect.origin`.  Whether it is offset to the left or right is
            determined by the current layout direction in `NSApp`.
        - vOffset: The distance to vertically offset the tool tip below
            `rect.origin`.  Non-flipped (y = 0 at bottom) coordinates are assumed.
     */
    private func reposition(
        relativeTo rect: CGRect,
        in ownerWindow: NSWindow,
        hOffset: CGFloat,
        vOffset: CGFloat)
    {
        guard let screenRect = ownerWindow.screen?.visibleFrame else { return }
        let ownerRect = ownerWindow.convertToScreen(rect)
        
        let hSafetyPadding: CGFloat = 20
        
        var tipRect = frame
        tipRect.origin = ownerRect.origin
        
        // Position tool tip window slightly below the owner on the screen
        tipRect.origin.y -= tipRect.height + vOffset

        if NSApp.userInterfaceLayoutDirection == .leftToRight
        {
            /*
             Position the tool tip window to the right relative to the owner on
             the screen.
             */
            tipRect.origin.x += hOffset
            
            // Make sure we're not drawing off the right edge
            tipRect.origin.x = min(
                tipRect.origin.x,
                screenRect.maxX - tipRect.width - hSafetyPadding
            )
        }
        else
        {
            /*
             Position the tool tip window to the left relative to the owner on
             the screen.
             */
            tipRect.origin.x -= hOffset
            
            // Make sure we're not drawing off the left edge
            tipRect.origin.x =
                max(tipRect.origin.x, screenRect.minX + hSafetyPadding)
        }
        
        
        /*
         Make sure we're not drawing off the bottom edge of the visible area.
         Non-flipped coordinates (y = 0 at bottom) are assumed.
         If we are, move the tool tip above the onwer.
         */
        if tipRect.minY < screenRect.minY + vOffset  {
            tipRect.origin.y = ownerRect.maxY + vOffset
        }
        
        self.setFrameOrigin(tipRect.origin)
    }


    // -------------------------------------
    /// Provides thin border around the tool tip.
    private class BorderedView: NSView
    {
        override func draw(_ dirtyRect: NSRect)
        {
            super.draw(dirtyRect)
            
            guard let context = NSGraphicsContext.current?.cgContext else {
                return
            }
            
            context.setStrokeColor(NSColor.black.cgColor)
            context.stroke(self.frame, width: 2)
        }
    }
}
