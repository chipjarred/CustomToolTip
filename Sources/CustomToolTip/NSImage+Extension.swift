import AppKit

// -------------------------------------
internal extension NSImage
{
    // -------------------------------------
    /**
     The smallest `CGRect` that can encompass all of the pixels where
     `alpha` > `alphaThreshold`
     */
    func minMaskRect(alphaThreshold: CGFloat) -> CGRect?
    {
        guard let c = cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }
        
        let bitMap = NSBitmapImageRep(cgImage: c)
        
        guard let pixels = bitMap.rgbaPixels else { return nil }
        
        var minX: Int = Int.max
        var minY: Int = Int.max
        var maxX: Int = Int.min
        var maxY: Int = Int.min
        
        for y in 0..<bitMap.pixelsHigh
        {
            for x in 0..<bitMap.pixelsWide
            {
                let pixel = pixels[y * bitMap.pixelsWide + x]
                
                if pixel.alpha > alphaThreshold
                {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        
        return CGRect(
            x: CGFloat(minX),
            y: CGFloat(minY),
            width: CGFloat(maxX - minX + 1),
            height: CGFloat(maxY - minY + 1)
        )
    }
}
