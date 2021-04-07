import AppKit

// -------------------------------------
internal extension NSCursor
{
    // -------------------------------------
    /*
     What we *really* want is to get the minimum rectangle encompassing the
     visible (not transparent) portions of the cursor so that
     CustomToolTipWindow can position the tool tip in a way that is consistent
     with the standard tool tips.
     
     Unfortunately the actual cursor images have lots of slop all around, so we
     can't just use it's size.  And we can't just use the hotspot.  Instead we,
     quite annoyingly, have to just special case each kind of cursor.
     */
    func frame(for location: CGPoint) -> CGRect
    {
        let hotSpot = self.hotSpot
        let size = image.size
        
        var cursorRect = CGRect(
            origin: CGPoint(
                x: location.x,
                y: location.y - size.height
            ),
            size: size
        )
        
        switch self
        {
            case .arrow, .disappearingItem, .operationNotAllowed,
                 .dragCopy, .dragLink:
                cursorRect.origin.x -= hotSpot.x / 2
                cursorRect.origin.y += hotSpot.y * 2
                cursorRect.size.width -= hotSpot.x * 2
                cursorRect.size.height -= hotSpot.y
                
            case .pointingHand:
                cursorRect.origin.x -= hotSpot.x / 2
                cursorRect.origin.y += hotSpot.y * 2
                cursorRect.size.width -= hotSpot.x * 2
                cursorRect.size.height -= hotSpot.y * 1.5
                
            case .iBeam:
                cursorRect.origin.x -= hotSpot.x / 2
                cursorRect.origin.y += hotSpot.y
                cursorRect.size.height += size.height * 0.1
                
            case .crosshair:
                cursorRect.origin.x -= size.width / 3
                cursorRect.origin.y += size.height * 2 / 3
                cursorRect.size.width -= size.width / 3
                cursorRect.size.height -= size.height / 3

            case .closedHand, .openHand:
                cursorRect.origin.x -= hotSpot.x / 2
                cursorRect.origin.y += hotSpot.y * 3 / 2
                cursorRect.size.height -= hotSpot.y
                
            case .resizeLeft:
                cursorRect.origin.x -= (size.width - hotSpot.x) * 2 / 3
                cursorRect.origin.y += hotSpot.y * 4 / 3
                cursorRect.size.height -= hotSpot.y / 2
                
            case .resizeRight:
                cursorRect.origin.x -= (size.width - hotSpot.x) * 1 / 3
                cursorRect.origin.y += hotSpot.y * 4 / 3
                cursorRect.size.height -= hotSpot.y / 2
                
            case .resizeLeftRight, .resizeUpDown:
                cursorRect.origin.x -= size.width / 3
                cursorRect.origin.y += size.height * 2 / 3
                cursorRect.size.width -= size.width / 3
                cursorRect.size.height -= size.height * 2 / 8

            case .resizeUp:
                cursorRect.origin.x -= (size.width - hotSpot.x) * 2 / 3
                cursorRect.origin.y += hotSpot.y * 5 / 3
                cursorRect.size.height -= (size.height - hotSpot.y) * 4 / 5
                
            case .resizeDown:
                cursorRect.origin.x -= (size.width - hotSpot.x) * 2 / 3
                cursorRect.origin.y += hotSpot.y * 4 / 3
                cursorRect.size.height -= (size.height - hotSpot.y)
                
            case .contextualMenu:
                cursorRect.origin.x -= hotSpot.x / 2
                cursorRect.origin.y += hotSpot.y * 5
                cursorRect.size.width -= hotSpot.x * 2
                cursorRect.size.height -= hotSpot.y * 4.5

            case .iBeamCursorForVerticalLayout:
                cursorRect.origin.x -= (size.width - hotSpot.x) * 2 / 3
                cursorRect.origin.y += hotSpot.y * 3
                cursorRect.size.width -= (size.width - hotSpot.x) * 2 / 3
                cursorRect.size.height -= hotSpot.y * 3 / 2
                
            default:
                /*
                 Unknown cursor type - probably a user defined one.
                 Tool tip will be positioned strangely, but should still be
                 out of the way of the cursor.
                 */
                break
        }
        
        return cursorRect
    }
}
