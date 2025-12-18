async function testLogin() {
    try {
        const response = await fetch('http://localhost:3000/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: 'admin@gym.com',
                password: 'admin123'
            })
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        console.log('Login Successful!');
        console.log('Token:', data.access_token ? 'Received' : 'Missing');
        // console.log('User:', data.user); // User might not be in response depending on implementation
    } catch (error) {
        console.error('Login Failed:', error.message);
    }
}

testLogin();
