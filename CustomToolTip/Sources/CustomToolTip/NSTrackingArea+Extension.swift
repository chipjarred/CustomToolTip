import AppKit

// -------------------------------------
/*
 Convenice extension for updating a tracking area's `rect` property.
 */
internal extension NSTrackingArea
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

