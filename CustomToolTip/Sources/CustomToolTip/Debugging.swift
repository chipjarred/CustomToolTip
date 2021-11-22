// -------------------------------------
internal func trace(
    _ message: @autoclosure () -> String = "",
    function: StaticString = #function,
    file: StaticString = #fileID,
    line: UInt = #line)
{
    #if DEBUG
    print("\(file): \(line): \(function): \(message())")
    #endif
}
