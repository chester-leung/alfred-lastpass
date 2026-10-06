// clear.js <changeCount> <seconds>: after a delay, clears the clipboard only if
// nothing has been copied since we set it.
ObjC.import('AppKit')

function run(argv) {
    delay(parseInt(argv[1], 10))
    const pb = $.NSPasteboard.generalPasteboard
    if (Number(pb.changeCount) === parseInt(argv[0], 10)) pb.clearContents
}
