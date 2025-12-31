import axios from 'axios';

const BASE_URL = 'http://localhost:3000';

async function run() {
  try {
    console.log('🚀 Debugging Gym Schedule...');

    // 1. Teacher Login (to create a student or use existing execution doesn't matter, just need a valid token)
    // Actually, let's just use Admin login which matches the seed
    const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'admin@gym.com',
      password: 'admin123',
    });
    const token = loginRes.data.access_token;
    console.log('✅ Logged In');

    // 2. Fetch Schedule
    const res = await axios.get(`${BASE_URL}/gym-schedule`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    console.log('Response Status:', res.status);
    console.log('Response Data:', JSON.stringify(res.data, null, 2));

    if (Array.isArray(res.data) && res.data.length > 0) {
      console.log('✅ Schedule found with ' + res.data.length + ' entries.');
    } else {
      console.log('❌ Schedule is empty or invalid format.');
    }
  } catch (error: any) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

run();
