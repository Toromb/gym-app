$baseUrl = "http://localhost:3000"

# 1. Login as Profe
echo "Logging in as Profe..."
$loginBody = @{
    email = "profe@gym.com"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.access_token
    echo "Logged in. Token acquired."
} catch {
    echo "Login failed: $_"
    exit
}

$headers = @{
    Authorization = "Bearer $token"
}

# 2. Get Students
echo "Fetching students..."
try {
    $students = Invoke-RestMethod -Uri "$baseUrl/users" -Method Get -Headers $headers
    if ($students.Count -eq 0) {
        echo "No students found for this professor. Creating one..."
        # Create a student
        $newStudentBody = @{
            email = "debug_student_$(Get-Random)@test.com"
            password = "password123"
            firstName = "Debug"
            lastName = "Student"
            role = "alumno"
        } | ConvertTo-Json
        $newStudent = Invoke-RestMethod -Uri "$baseUrl/users" -Method Post -Body $newStudentBody -Headers $headers -ContentType "application/json"
        echo "Created student: $($newStudent.id)"
        $studentId = $newStudent.id
    } else {
        $studentId = $students[0].id
        echo "Using student: $studentId ($($students[0].email))"
    }
} catch {
    echo "Error fetching/creating students: $_"
    exit
}

# 3. Get Plans
echo "Fetching plans..."
try {
    $plans = Invoke-RestMethod -Uri "$baseUrl/plans" -Method Get -Headers $headers
    if ($plans.Count -eq 0) {
        echo "No plans found. Creating one..."
        $newPlanBody = @{
            name = "Debug Plan"
            objective = "Debug"
            durationWeeks = 4
            generalNotes = "Test"
            weeks = @()
        } | ConvertTo-Json
        $newPlan = Invoke-RestMethod -Uri "$baseUrl/plans" -Method Post -Body $newPlanBody -Headers $headers -ContentType "application/json"
        echo "Created plan: $($newPlan.id)"
        $planId = $newPlan.id
    } else {
        $planId = $plans[0].id
        echo "Using plan: $planId ($($plans[0].name))"
    }
} catch {
    echo "Error fetching/creating plans: $_"
    exit
}

# 4. Assign Plan
echo "Assigning plan $planId to student $studentId..."
$assignBody = @{
    planId = $planId
    studentId = $studentId
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "$baseUrl/plans/assign" -Method Post -Body $assignBody -Headers $headers -ContentType "application/json"
    echo "SUCCESS: Plan assigned."
} catch {
    echo "FAILURE: Assignment failed."
    echo $_.Exception.Response.StatusCode.value__
    $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $errorResponse = $streamReader.ReadToEnd()
    echo $errorResponse
}
