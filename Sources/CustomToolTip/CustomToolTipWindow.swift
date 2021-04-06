import AppKit

// MARK:- Custom Tool Tip Window
// -------------------------------------
/**
 Window for displaying custom tool tips.
 */
internal final class CustomToolTipWindow: NSWindow
{
    public static let defaultMargins: CGSize = CGSize(width: 5, height: 5)
    public static let defaultBackColor: NSColor = .windowBackgroundColor
    
    // -------------------------------------
    public static func makeAndShow(
        toolTipView: NSView,
        for owner: NSView,
        margins: CGSize = defaultMargins,
        backgroundColor: NSColor = defaultBackColor,
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
                    to: ownerWindow.contentView
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
        
        let cursorSize = NSCursor.current.image.size
        let mouseRect = CGRect(
            origin: CGPoint(
                x: mouseLocation.x,
                y: mouseLocation.y - cursorSize.height
            ),
            size: NSCursor.current.image.size
        )
        
        reposition(
            relativeTo: mouseRect,
            in: ownerWindow,
            hOffset: 0,
            vOffset: 0
        )
    }
    
    // -------------------------------------
    /*
     - Parameters:
        - rect: `CGRect` in the coordinates of the tool tip owning view's
            window.
        - ownerWindow: The window to which the tool tip owning view belongs
     */
    private func reposition(
        relativeTo rect: CGRect,
        in ownerWindow: NSWindow,
        hOffset: CGFloat,
        vOffset: CGFloat)
    {
        guard let screenRect = ownerWindow.screen?.visibleFrame else { return }
        let winRect = ownerWindow.convertToScreen(rect)
        
        let hSafetyPadding: CGFloat = 20
        
        var newRect = frame
        newRect.origin = winRect.origin
        
        // Position tool tip window slightly below the onwer on the screen
        newRect.origin.y -= newRect.height + vOffset

        if NSApp.userInterfaceLayoutDirection == .leftToRight
        {
            /*
             Position the tool tip window to the right relative to the owner on
             the screen.
             */
            newRect.origin.x += hOffset
            
            // Make sure we're not drawing off the right edge
            newRect.origin.x = min(
                newRect.origin.x,
                screenRect.maxX - newRect.width - hSafetyPadding
            )
        }
        else
        {
            /*
             Position the tool tip window to the left relative to the owner on
             the screen.
             */
            newRect.origin.x -= hOffset
            
            // Make sure we're not drawing off the left edge
            newRect.origin.x =
                max(newRect.origin.x, screenRect.minX + hSafetyPadding)
        }
        
        
        /*
         Make sure we're not drawing off the bottom edge of the visible area.
         Non-flipped coordinates (y = 0 at bottom) are assumed.
         If we are, move the tool tip above the onwer.
         */
        if newRect.minY < screenRect.minY  {
            newRect.origin.y = winRect.maxY + vOffset
        }
        
        self.setFrameOrigin(newRect.origin)
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
