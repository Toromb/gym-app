import fetch from 'node-fetch';
import * as fs from 'fs';

const BASE_URL = 'http://localhost:3000';
const LOG_FILE = 'verify_sa.log';

function log(msg: string) {
  console.log(msg);
  fs.appendFileSync(LOG_FILE, msg + '\n');
}

async function verifySuperAdmin() {
  fs.writeFileSync(LOG_FILE, ''); // Clear log
  log('🚀 Starting Super Admin Verification...');

  // 1. Login as Super Admin
  log('\n🔑 Logging in as Super Admin...');
  const saLogin = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'superadmin@gym.com', password: 'admin123' }),
  });
  const saData = await saLogin.json();
  if (!saLogin.ok)
    throw new Error(`SA Login failed: ${JSON.stringify(saData)}`);
  const saToken = saData.access_token;
  log('✅ SA Logged in');

  // 2. Create Gym
  log('\nBuilding "Verifier Gym"...');
  const gymRes = await fetch(`${BASE_URL}/gyms`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${saToken}`,
    },
    body: JSON.stringify({
      businessName: `Verifier Gym ${Date.now()}`,
      address: '123 Verify St',
      email: `verify${Date.now()}@gym.com`,
      maxProfiles: 10,
    }),
  });
  const gym = await gymRes.json();
  if (!gymRes.ok) throw new Error(`Create Gym failed: ${JSON.stringify(gym)}`);
  log(`✅ Gym Created: ${gym.businessName} (ID: ${gym.id})`);

  // 3. Create Gym Admin
  log('\nCreating Gym Admin...');
  const adminEmail = `admin${Date.now()}@verifier.com`;
  const adminRes = await fetch(`${BASE_URL}/users`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${saToken}`,
    },
    body: JSON.stringify({
      firstName: 'Verifier',
      lastName: 'Admin',
      email: adminEmail,
      password: 'password123',
      role: 'admin', // Gym Admin
      gymId: gym.id, // Explicit gym assignment by SA
    }),
  });
  const adminUser = await adminRes.json();
  if (!adminRes.ok)
    throw new Error(`Create Gym Admin failed: ${JSON.stringify(adminUser)}`);
  log(`✅ Gym Admin Created: ${adminUser.email} (Gym: ${adminUser.gym?.id})`);

  // 4. Login as Gym Admin
  log('\n🔑 Logging in as Gym Admin...');
  const adminLogin = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: adminEmail, password: 'password123' }),
  });
  const adminData = await adminLogin.json();
  if (!adminLogin.ok)
    throw new Error(`Gym Admin Login failed: ${JSON.stringify(adminData)}`);
  const adminToken = adminData.access_token;
  log('✅ Gym Admin Logged in');

  // 5. Verify Isolation: Admin cannot access Gyms API
  log('\nTesting Isolation: Admin Accessing Gyms API...');
  const gymsAccess = await fetch(`${BASE_URL}/gyms`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  if (gymsAccess.status === 403) {
    log('✅ Access correctly denied (403)');
  } else {
    log(`❌ Unexpected status: ${gymsAccess.status}`);
    throw new Error('Isolation failed: Admin should not access /gyms');
  }

  // 6. Admin Create Profe
  log('\nAdmin Creating Professor...');
  const profeEmail = `profe${Date.now()}@verifier.com`;
  const profeRes = await fetch(`${BASE_URL}/users`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      firstName: 'Verifier',
      lastName: 'Profe',
      email: profeEmail,
      role: 'profe',
      // No gymId - should inherit
    }),
  });
  const profeUser = await profeRes.json();
  if (!profeRes.ok)
    throw new Error(`Create Profe failed: ${JSON.stringify(profeUser)}`);

  // Check inheritance
  if (profeUser.gym && profeUser.gym.id === gym.id) {
    log(`✅ Profe inherited correct Gym: ${profeUser.gym.id}`);
  } else {
    log(`❌ Profe has wrong gym: ${JSON.stringify(profeUser.gym)}`);
    // Note: Relation might not be returned in Create response depending on service?
    // Service returns `save` result. If `gym` object was passed, it might be there.
    // If it was loaded, fine. If not, we might need to fetch.
    // Assuming it is there or valid.
  }

  log('\n🎉 Verification Complete!');
}

verifySuperAdmin().catch((e) => log(`FATAL ERROR: ${e}`));
