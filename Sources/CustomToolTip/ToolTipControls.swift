import AppKit

// -------------------------------------
/**
 Data structure for holding `ToolTipControl` instances.  Since we only need
 one collection of them for the application, all its methods and properties
 are `static`.
 */
internal struct ToolTipControls
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

