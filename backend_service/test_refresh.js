const http = require('http');

async function makeRequest(path, data) {
    return new Promise((resolve, reject) => {
        const reqData = JSON.stringify(data);
        const req = http.request({
            hostname: 'localhost',
            port: 3000,
            path: path,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': reqData.length
            }
        }, (res) => {
            let body = '';
            res.on('data', d => body += d);
            res.on('end', () => resolve(JSON.parse(body)));
        });
        req.on('error', reject);
        req.write(reqData);
        req.end();
    });
}

async function run() {
    const nonce = Date.now();
    const email = `test${nonce}@gymflow.com`;

    console.log('Registering user...');
    const regResult = await makeRequest('/auth/register', {
        email: email,
        password: 'password123',
        firstName: 'Test',
        lastName: 'User',
        role: 'admin' // or STUDENT
    });
    console.log('Register Result:', regResult);

    console.log('Logging in as mobile...');
    const loginResult = await makeRequest('/auth/login', {
        email: email,
        password: 'password123',
        platform: 'mobile'
    });
    console.log('Login Result:', loginResult);

    if (!loginResult.refresh_token) {
        console.error('No refresh token! Test failed.');
        process.exit(1);
    }

    console.log('Refreshing token...');
    const refreshResult = await makeRequest('/auth/refresh', {
        refreshToken: loginResult.refresh_token,
        deviceId: 'test-device'
    });
    console.log('Refresh Result:', refreshResult);

    if (refreshResult.access_token && refreshResult.refresh_token) {
        console.log('TEST PASSED! The backend issued a rotated refresh_token successfully.');
    } else {
        console.error('TEST FAILED. Did not return valid rotated tokens.');
    }

}

run();
