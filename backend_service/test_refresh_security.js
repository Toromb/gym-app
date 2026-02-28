const http = require('http');

async function makeRequest(path, data, token = null) {
    return new Promise((resolve, reject) => {
        const reqData = JSON.stringify(data);
        const headers = {
            'Content-Type': 'application/json',
            'Content-Length': reqData.length
        };
        if (token) headers['Authorization'] = `Bearer ${token}`;

        const req = http.request({
            hostname: 'localhost',
            port: 3000,
            path: path,
            method: 'POST',
            headers: headers
        }, (res) => {
            let body = '';
            res.on('data', d => body += d);
            res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body) }));
        });
        req.on('error', reject);
        req.write(reqData);
        req.end();
    });
}

async function runTests() {
    const email = `test_security_${Date.now()}@gymflow.com`;
    const password = 'password123';

    console.log('\n--- 1. Registering Test User ---');
    await makeRequest('/auth/register', {
        email, password, firstName: 'Security', lastName: 'Test', role: 'admin'
    });

    console.log('\n--- 2. Mobile Login (Initial Tokens) ---');
    const loginRes = await makeRequest('/auth/login', {
        email, password, platform: 'mobile', deviceId: 'test-device-1'
    });
    let tokens = loginRes.body;
    if (!tokens.refresh_token) return console.error('FAILED TO GET INITIAL TOKENS');
    console.log('✅ Success: Received Refesh Token 1');

    console.log('\n--- 3. Normal Token Rotation ---');
    const refreshRes1 = await makeRequest('/auth/refresh', {
        refreshToken: tokens.refresh_token, deviceId: 'test-device-1'
    });
    if (refreshRes1.status !== 201) return console.error('FAILED TO ROTATE TOKEN', refreshRes1);
    let tokens2 = refreshRes1.body;
    console.log('✅ Success: Received Refesh Token 2 (Rotated)');

    console.log('\n--- 4. Token Theft Detection (Replay Attack) ---');
    console.log('Attempting to use the OLD (Token 1) again...');
    const theftRes = await makeRequest('/auth/refresh', {
        refreshToken: tokens.refresh_token, deviceId: 'hacker-device'
    });
    if (theftRes.status === 401 && theftRes.body.message.includes('breach')) {
        console.log('✅ Success: Backend detected theft and blocked access:', theftRes.body.message);
    } else {
        return console.error('FAILED TO DETECT THEFT', theftRes);
    }

    console.log('\n--- 5. Verify Lockdown (Token 2 shouldn\'t work anymore) ---');
    const legitRes = await makeRequest('/auth/refresh', {
        refreshToken: tokens2.refresh_token, deviceId: 'test-device-1'
    });
    if (legitRes.status === 401) {
        console.log('✅ Success: Backend correctly purged ALL sessions during the lockdown.');
    } else {
        return console.error('FAILED: Active session survived a lockdown!', legitRes);
    }

    console.log('\n--- 6. Password Change Revocation ---');
    console.log('Logging in again to get fresh tokens...');
    const loginRes2 = await makeRequest('/auth/login', {
        email, password, platform: 'mobile', deviceId: 'test-device-1'
    });
    const tokens3 = loginRes2.body;

    console.log('Changing password...');
    await makeRequest('/auth/change-password', {
        currentPassword: password, newPassword: 'newpassword123'
    }, tokens3.access_token);

    console.log('Attempting to use pre-password-change Refresh Token...');
    const postPwRes = await makeRequest('/auth/refresh', {
        refreshToken: tokens3.refresh_token, deviceId: 'test-device-1'
    });
    if (postPwRes.status === 401) {
        console.log('✅ Success: Tokens were revoked after password change.');
    } else {
        return console.error('FAILED: Tokens survived password change!', postPwRes);
    }

    console.log('\n🎉 ALL SECURITY TESTS PASSED 🎉');
}

runTests();
