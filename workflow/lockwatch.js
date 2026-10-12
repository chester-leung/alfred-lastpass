// Run by launchd (KeepAlive, installed on login by action.sh):
//   osascript -l JavaScript lockwatch.js [agent pattern]
// Locks lpass (stops the agent holding the decryption key) as soon as the
// screen locks or the Mac goes to sleep.
ObjC.import('AppKit')

let pattern = '^lpass \\[agent\\]'

function lock() {
    const task = $.NSTask.alloc.init
    task.launchPath = '/usr/bin/pkill'
    task.arguments = $(['-TERM', '-U', $.NSUserName().js, '-f', pattern])
    task.launch
    task.waitUntilExit
}

ObjC.registerSubclass({
    name: 'LastPassLockWatcher',
    methods: {
        'lock:': { types: ['void', ['id']], implementation: () => lock() },
    },
})

function run(argv) {
    if (argv[0]) pattern = argv[0]  // for testing against a dummy process
    const watcher = $.LastPassLockWatcher.alloc.init
    $.NSDistributedNotificationCenter.defaultCenter
        .addObserverSelectorNameObject(watcher, 'lock:', 'com.apple.screenIsLocked', $())
    $.NSWorkspace.sharedWorkspace.notificationCenter
        .addObserverSelectorNameObject(watcher, 'lock:', $.NSWorkspaceWillSleepNotification, $())
    $.NSRunLoop.currentRunLoop.run
}
