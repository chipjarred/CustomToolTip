import AppKit

// -------------------------------------
internal extension NSCursor
{
    // -------------------------------------
    /*
     Gets the smallest `CGRect` that fully encloses the non-transparent
     portions of the mouse cursor's image.
     */
    func frame(for location: CGPoint) -> CGRect
    {
        let hotSpot = self.hotSpot
                
        /*
         First try to get cursorRect the "right" way... which is to extract the
         minimum CGRect that contains the masked portions (ie. alpha
         channel > some threshold). This can fail if the image's bitmap isn't
         in RGBA format.
         */
        if var cursorRect = image.minMaskRect(alphaThreshold: 0.5)
        {
            cursorRect.origin.x += location.x - hotSpot.x
            cursorRect.origin.y = location.y - cursorRect.minY + hotSpot.y
            cursorRect.origin.y -= cursorRect.height
            return cursorRect
        }
        
        /*
         If getting the proper cursorRect from the actual image fails, we fall
         back on some unfortunately excessive special cases that I determined by
         trial and error.
         */
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
