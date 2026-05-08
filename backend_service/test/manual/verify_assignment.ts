import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';

const BASE_URL = 'http://localhost:3000';

async function verifyAssignment() {
  try {
    console.log('🚀 Verifying Admin Assign Professor...');

    // 1. Admin Login
    const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'admin@gym.com',
      password: 'admin123',
    });
    const adminToken = loginRes.data.access_token;
    console.log('✅ Admin Logged In');

    // 2. Create Teacher
    const teacherEmail = `teacher_${uuidv4().substring(0, 8)}@test.com`;
    const teacherRes = await axios.post(
      `${BASE_URL}/users`,
      {
        email: teacherEmail,
        password: 'password123',
        firstName: 'Teacher',
        lastName: 'Test',
        role: 'profe',
      },
      { headers: { Authorization: `Bearer ${adminToken}` } },
    );
    const teacherId = teacherRes.data.id;
    console.log(`✅ Teacher Created: ${teacherEmail} (${teacherId})`);

    // 3. Create Student (Unassigned initially)
    const studentEmail = `student_${uuidv4().substring(0, 8)}@test.com`;
    const studentRes = await axios.post(
      `${BASE_URL}/users`,
      {
        email: studentEmail,
        password: 'password123',
        firstName: 'Student',
        lastName: 'Test',
        role: 'alumno',
        // professorId: null // Explicitly no professor
      },
      { headers: { Authorization: `Bearer ${adminToken}` } },
    );
    const studentId = studentRes.data.id;
    console.log(`✅ Student Created: ${studentEmail} (${studentId})`);

    // Verify initial state
    if (studentRes.data.professor) {
      console.error('❌ Student should not have a professor yet');
    } else {
      console.log('✅ Student correctly has no professor initially');
    }

    // 4. Update Student to assign Professor
    console.log('🔄 Assigning Professor to Student...');
    const updateRes = await axios.patch(
      `${BASE_URL}/users/${studentId}`,
      {
        professorId: teacherId,
      },
      { headers: { Authorization: `Bearer ${adminToken}` } },
    );

    if (updateRes.data.professor && updateRes.data.professor.id === teacherId) {
      console.log('✅ Professor successfully assigned via PATCH');
    } else {
      console.error('❌ Failed to assign professor. Res:', updateRes.data);
      process.exit(1);
    }

    // 5. Verify via Get User
    const getRes = await axios.get(`${BASE_URL}/users/${studentId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });

    if (getRes.data.professor && getRes.data.professor.id === teacherId) {
      console.log('✅ Verified persistence via GET');
    } else {
      console.error('❌ Verification failed on GET');
    }
  } catch (error: any) {
    console.error('❌ Error:', error.response?.data || error.message);
    process.exit(1);
  }
}

verifyAssignment();
