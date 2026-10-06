// Copies stdin to the clipboard and prints the pasteboard change count.
// `conceal` marks it per nspasteboard.org so clipboard managers skip it.
ObjC.import('AppKit')

function run(argv) {
    const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile
    const text = ($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js || '').replace(/\n$/, '')
    if (!text) return ''
    const pb = $.NSPasteboard.generalPasteboard
    pb.clearContents
    pb.setStringForType($(text), $.NSPasteboardTypeString)
    if (argv[0] === 'conceal') {
        pb.setStringForType($(''), 'org.nspasteboard.ConcealedType')
        pb.setStringForType($(''), 'org.nspasteboard.TransientType')
    }
    return String(pb.changeCount)
}
