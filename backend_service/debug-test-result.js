
const crypto = require('crypto');
const http = require('http');

// CONFIG
const JWT_SECRET = 'prod_secret_key_999';
const GYM_ID = '37488b6c-3352-4691-bb4c-8a3c4980b71b';
const HOST = 'localhost';
const PORT = 3000;

function base64UrlEncode(str) {
    return Buffer.from(str).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function signJwt(payload, secret) {
    const header = { alg: 'HS256', typ: 'JWT' };
    const encodedHeader = base64UrlEncode(JSON.stringify(header));
    const encodedPayload = base64UrlEncode(JSON.stringify(payload));
    const signature = crypto.createHmac('sha256', secret).update(`${encodedHeader}.${encodedPayload}`).digest('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
    return `${encodedHeader}.${encodedPayload}.${signature}`;
}

function sendRequest(data) {
    return new Promise((resolve, reject) => {
        const postData = JSON.stringify(data);
        const options = {
            hostname: HOST,
            port: PORT,
            path: '/auth/apple',
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(postData) }
        };
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => resolve({ status: res.statusCode, body: body }));
        });
        req.on('error', e => reject(e));
        req.write(postData);
        req.end();
    });
}

async function runTest() {
    console.log('[C] Testing New User with VALID Invite...');
    const validInvite = signJwt({ gymId: GYM_ID, role: 'student', exp: Math.floor(Date.now() / 1000) + 3600 }, JWT_SECRET);

    try {
        const res = await sendRequest({ identityToken: 'TEST_TOKEN_APPLE', inviteToken: validInvite });
        console.log(`STATUS: ${res.status}`);
        console.log(`BODY: ${res.body}`);
    } catch (e) { console.error(e); }
}

runTest();
