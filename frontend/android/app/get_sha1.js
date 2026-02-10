const fs = require('fs');
const content = fs.readFileSync('fingerprint.txt', 'utf16le');
let out = '';
const sha1Match = content.match(/SHA1: ([:A-F0-9]+)/);
if (sha1Match) out += 'SHA1: ' + sha1Match[1] + '\r\n';
const sha256Match = content.match(/SHA256: ([:A-F0-9]+)/);
if (sha256Match) out += 'SHA256: ' + sha256Match[1] + '\r\n';
fs.writeFileSync('sha1_out.txt', out);
