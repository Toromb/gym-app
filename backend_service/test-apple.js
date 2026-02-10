
const http = require('http');
const jwt = require('jsonwebtoken');

// CONFIG
// In container, we might have env vars or we can hardcode for test matching
const JWT_SECRET = process.env.JWT_SECRET || 'prod_secret_key_999';
const GYM_ID = '37488b6c-3352-4691-b4c6-8a3c4980b71b'; // Retrieved from DB
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

async function runTests() {
    console.log('--- STARTING APPLE SIGN IN TESTS (INSIDE CONTAINER) ---');
    console.log(`Using JWT_SECRET: ${JWT_SECRET.substring(0, 3)}***`);

    // SCENARIO A: New User, No Invite
    console.log('\n[A] Testing New User without Invite (Expect 400)...');
    try {
        const resA = await sendRequest({ identityToken: 'TEST_TOKEN_APPLE' });
        console.log(`STATUS: ${resA.status}`);
        if (resA.status === 400) console.log('PASS: Correctly rejected.');
        else console.log(`FAIL: Expected 400. Got ${resA.status}`);
    } catch (e) { console.error(e); }

    // SCENARIO B: New User, Invalid Invite
    console.log('\n[B] Testing New User with Invalid Invite (Expect 400)...');
    try {
        const resB = await sendRequest({ identityToken: 'TEST_TOKEN_APPLE', inviteToken: 'INVALID_TOKEN' });
        console.log(`STATUS: ${resB.status}`);
        if (resB.status === 400) console.log('PASS: Correctly rejected.');
        else console.log(`FAIL: Expected 400. Got ${resB.status}`);
    } catch (e) { console.error(e); }

    // SCENARIO C: New User, Valid Invite
    console.log('\n[C] Testing New User with VALID Invite (Expect 201 Created)...');
    // Use jsonwebtoken library available in container
    const validInvite = jwt.sign({ gymId: GYM_ID, role: 'student' }, JWT_SECRET, { expiresIn: '1h' });
    console.log(`Generated Token: ${validInvite}`);
    try {
        const verified = jwt.verify(validInvite, JWT_SECRET);
        console.log(`Self-Verification Success: Linked to Gym ${verified.gymId}`);
    } catch (verErr) {
        console.error(`Self-Verification Failed: ${verErr.message}`);
    }

    try {
        const resC = await sendRequest({ identityToken: 'TEST_TOKEN_APPLE', inviteToken: validInvite });
        console.log(`STATUS: ${resC.status}`);
        if (resC.status === 201) console.log('PASS: User created/logged in.');
        else console.log(`FAIL: Expected 201. Got ${resC.status} - ${resC.body}`);
    } catch (e) { console.error(e); }

    // SCENARIO D: Existing User (Login)
    console.log('\n[D] Testing Existing User Login (Expect 201/200)...');
    try {
        const resD = await sendRequest({ identityToken: 'TEST_TOKEN_APPLE' });
        console.log(`STATUS: ${resD.status}`);
        if (resD.status === 201 || resD.status === 200) console.log('PASS: Login successful.');
        else console.log(`FAIL: Expected 200/201. Got ${resD.status} - ${resD.body}`);
    } catch (e) { console.error(e); }

    console.log('\n--- TESTS A-D COMPLETED ---');
}

runTests();
