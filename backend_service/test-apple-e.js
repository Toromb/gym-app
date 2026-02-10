
const http = require('http');

const HOST = 'localhost';
const PORT = 3000;

function sendRequest(data) {
    return new Promise((resolve, reject) => {
        const postData = JSON.stringify(data);
        const options = {
            hostname: HOST,
            port: PORT,
            path: '/auth/apple',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData),
            },
        };

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                resolve({ status: res.statusCode, body });
            });
        });

        req.on('error', (e) => reject(e));
        req.write(postData);
        req.end();
    });
}

async function runTest() {
    console.log('\n[E] Testing Existing User (Unlinked) (Expect 403 Forbidden)...');
    try {
        // Send only identityToken, user exists (from previous test) but is unlinked
        const res = await sendRequest({ identityToken: 'TEST_TOKEN_APPLE' });
        console.log(`STATUS: ${res.status}`);
        console.log(`BODY: ${res.body}`);

        if (res.status === 403) {
            console.log('PASS: User rejected (403 Forbidden).');
        } else {
            console.log(`FAIL: Expected 403. Got ${res.status}.`);
            process.exit(1);
        }
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

runTest();
