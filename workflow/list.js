// Turns `lpass ls --format` output (stdin) into Alfred Script Filter JSON.
ObjC.import('Foundation')

const SECURE_NOTE_URL = 'http://sn'

function action(name, extra = {}) {
    return Object.assign({ arg: '', variables: { action: name } }, extra)
}

function run(argv) {
    const mode = argv[0]
    let items = []

    if (mode === 'missing') {
        items = [{ title: 'lpass not found', valid: false,
            subtitle: 'Install lastpass-cli, or set the lpass_path workflow variable' }]
    } else if (mode === 'login') {
        items = [action('login', { title: 'Log in to LastPass',
            subtitle: 'Asks for your email, master password and MFA code' })]
    } else if (mode === 'unlock') {
        items = [action('unlock', { title: 'Unlock LastPass',
            subtitle: 'Asks for your master password' }),
            action('logout', { title: 'Log out of LastPass', subtitle: 'Remove the local session and cache' })]
    } else {
        const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile
        const text = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js || ''
        for (const line of text.split('\n')) {
            const f = line.split('\x1f')
            if (f.length !== 5 || !/^\d+$/.test(f[0])) continue
            const [id, name, user, url, group] = f
            const folder = group.replace(/\/$/, '')
            if (url === SECURE_NOTE_URL) {
                items.push({
                    uid: id, title: name, arg: id,
                    subtitle: ['Secure note', folder].filter(Boolean).join(' · '),
                    match: `${name} ${folder} note`,
                    variables: { action: 'notes' },
                    mods: {
                        cmd: { valid: false, subtitle: 'No username' },
                        alt: { valid: false, subtitle: 'No URL' },
                    },
                })
                continue
            }
            const host = (url.match(/^[a-z][\w+.-]*:\/\/([^\/?#]+)/i) || [, url])[1]
            items.push({
                uid: id, title: name, arg: id,
                subtitle: [user, host, folder].filter(Boolean).join(' · '),
                match: `${name} ${user} ${host} ${folder}`,
                variables: { action: 'password' },
                text: { copy: user, largetype: user || name },
                mods: {
                    cmd: { arg: id, valid: !!user, subtitle: `Copy username: ${user}`,
                        variables: { action: 'username' } },
                    alt: { arg: id, valid: !!url, subtitle: `Open ${url}`,
                        variables: { action: 'url' } },
                },
            })
        }
        if (items.length === 0) {
            items.push({ title: 'Vault is empty or not synced yet', valid: false,
                subtitle: 'Try "Sync LastPass vault" in a moment' })
        }
        items.push(action('sync', { title: 'Sync LastPass vault', match: 'sync refresh lastpass',
            subtitle: 'Fetch the latest vault from LastPass' }))
        items.push(action('logout', { title: 'Log out of LastPass', match: 'logout log out lock lastpass',
            subtitle: 'Remove the local session and cache now' }))
    }
    return JSON.stringify({ items })
}
