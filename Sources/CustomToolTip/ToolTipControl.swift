import AppKit

// -------------------------------------
/**
 Data structure to hold information used for holding the tool tip and for
 controlling when to show or hide it.
 */
internal struct ToolTipControl
{
    /**
     `Date` when mouse was last moved within the tracking area.  Should be
     `nil` when the mouse is not in the tracking area.
     */
    private(set) var mouseEntered: Date?
    
    var mouseLocation: CGPoint? {
        didSet { mouseEntered = mouseLocation == nil ? nil : Date() }
    }
    
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
    var toolTipMargins: CGSize = CustomToolTipWindow.defaultMargins
    
    /// Tool tip window's background color
    var toolTipBackgroundColor: NSColor = CustomToolTipWindow.defaultBackColor
    
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
