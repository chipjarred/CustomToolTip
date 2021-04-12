import AppKit

// -------------------------------------
internal extension NSBitmapImageRep
{
    /*
     It's not clear to me if alphaFirst means ABGR or ARGB, and Apple's docs
     are no help so far, so I implement it both ways, and will just see what
     results I get.
     */
    fileprivate static var alphaFirstMeansABGRNotARGB: Bool { true }
    
    // -------------------------------------
    struct RGBAPixel
    {
        var red, green, blue, alpha: CGFloat
        
        // -------------------------------------
        fileprivate init<S: RandomAccessCollection>(_ components: S)
            where S.Element == CGFloat, S.Index == Int
        {
            assert(components.count == 4)
            var i = components.startIndex
            self.red   = components[i]
            
            i = components.index(after: i)
            self.green = components[i]
            
            i = components.index(after: i)
            self.blue  = components[i]
            
            i = components.index(after: i)
            self.alpha = components[i]
        }
        
        // -------------------------------------
        fileprivate mutating func toAlphaFirst()
        {
            if NSBitmapImageRep.alphaFirstMeansABGRNotARGB
            {
                swap(&red, &alpha)
                swap(&green, &blue)
            }
            else
            {
                let tempAlpha = alpha
                alpha = blue
                blue = green
                green = red
                red = tempAlpha
            }
        }
    }
    
    // -------------------------------------
    var rgbaPixels: [RGBAPixel]?
    {
        guard samplesPerPixel == 4,
            let components = cgFloatValues
        else { return nil }
        
        var pixels = [RGBAPixel]()
        pixels.reserveCapacity(components.count / 4)
        
        for i in stride(from: 0, to: components.count, by: 4) {
            pixels.append(.init(components[i..<(i+4)]))
        }
        
        if bitmapFormat.contains(.alphaFirst) {
            pixels.indices.forEach { pixels[$0].toAlphaFirst() }
        }
        
        return pixels
    }
    
    // -------------------------------------
    private var cgFloatValues: [CGFloat]?
    {
        if bitmapFormat.contains(.floatingPointSamples)
        {
            /*
             NOTE: big endian formats are specifically supported for integer
             types, but is missing for float.  Does that mean bitmap floats are
             never big endian in bitmaps?  Also are they actually Float or
             Double?
             */
            return mapToCGFloats { (x: Float) -> CGFloat in CGFloat(x) }
        }
        else if bitmapFormat.contains(.thirtyTwoBitLittleEndian)
        {
            let divisor = CGFloat(UInt32.max)
            return mapToCGFloats {
                (x: UInt32) -> CGFloat in CGFloat(x) / divisor
            }
        }
        else if bitmapFormat.contains(.sixteenBitLittleEndian)
        {
            let divisor = CGFloat(UInt16.max)
            return mapToCGFloats {
                (x: UInt16) -> CGFloat in CGFloat(x) / divisor
            }
        }
        else if bitmapFormat.contains(.thirtyTwoBitBigEndian)
        {
            let divisor = CGFloat(UInt32.max)
            return mapToCGFloats {
                (x: UInt32) -> CGFloat in CGFloat(x.byteSwapped) / divisor
            }
        }
        else if bitmapFormat.contains(.sixteenBitBigEndian)
        {
            let divisor = CGFloat(UInt16.max)
            return mapToCGFloats {
                (x: UInt16) -> CGFloat in CGFloat(x.byteSwapped) / divisor
            }
        }
        
        let divisor = CGFloat(UInt8.max)
        return mapToCGFloats { (x: UInt8) -> CGFloat in CGFloat(x) / divisor }
    }
    
    // -------------------------------------
    private func mapToCGFloats<T>(
        using convert: (T) -> CGFloat) -> [CGFloat]?
    {
        guard let bytes = bitmapData else { return nil }
        
        let numBytes = 4 * pixelsWide * pixelsHigh * MemoryLayout<T>.stride
        return UnsafeMutableBufferPointer(start: bytes, count: numBytes)
            .withMemoryRebound(to: T.self) {  $0.map { convert($0) } }
    }
}
