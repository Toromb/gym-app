$base = "http://localhost:3000"

# 1. Login Professor
Write-Host "1. Logging in Professor..."
$profResponse = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType "application/json" -Body '{"email":"profetest@gym.com", "password":"admin123"}'
$profToken = $profResponse.access_token
Write-Host "   Success. Token obtained."

# 2. Find Student ID (Need to list students or login as student to get ID?)
# Easier: Login as student to get their ID from profile? Or search?
# Let's login as student first to get their ID.
Write-Host "2. Logging in Student to get ID..."
$studentResponse = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType "application/json" -Body '{"email":"alumnotest@gym.com", "password":"admin123"}'
$studentToken = $studentResponse.access_token
# Get Profile
$studentProfile = Invoke-RestMethod -Method Get -Uri "$base/users/profile" -Headers @{ Authorization = "Bearer $studentToken" }
$studentId = $studentProfile.id
Write-Host "   Student ID: $studentId"

# 3. Create Plan (as Professor)
Write-Host "3. Creating Plan..."
$planBody = @{
    name          = "Plan API Test"
    objective     = "Test via Script"
    durationWeeks = 4
    weeks         = @(
        @{
            weekNumber = 1
            days       = @(
                @{
                    dayOfWeek = 1
                    order     = 1
                    title     = "Dia 1"
                    exercises = @(
                        @{
                            exerciseId = "d54c1538-2a07-4f61-b530-01d063717df3" # Need a valid ID, assume seed exists or fetch?
                            # Using one from seed might be tricky without fetching first.
                            # Let's fetch exercises first.
                            sets       = 4
                            reps       = "10"
                            order      = 1
                        }
                    )
                }
            )
        }
    )
}

# Fetch exercises to get a valid ID
$exercises = Invoke-RestMethod -Method Get -Uri "$base/exercises" -Headers @{ Authorization = "Bearer $profToken" }
$exId = $exercises[0].id
$planBody.weeks[0].days[0].exercises[0].exerciseId = $exId

$planJson = $planBody | ConvertTo-Json -Depth 10
$plan = Invoke-RestMethod -Method Post -Uri "$base/plans" -Headers @{ Authorization = "Bearer $profToken" } -ContentType "application/json" -Body $planJson
$planId = $plan.id
Write-Host "   Plan Created. ID: $planId"


try {
    # 4. Assign Plan (as Professor)
    Write-Host "4. Assigning Plan..."
    $assignBody = @{
        studentId = $studentId
        planId    = $planId
        startDate = (Get-Date).ToString("yyyy-MM-dd")
    } | ConvertTo-Json

    Invoke-RestMethod -Method Post -Uri "$base/plans/assign" -Headers @{ Authorization = "Bearer $profToken" } -ContentType "application/json" -Body $assignBody
    Write-Host "   Plan Assigned."
}
catch {
    Write-Host "ERROR in Assign Plan: $_"
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
        Write-Host "Response Body: $body"
    }
    catch {
        Write-Host "Could not read response body."
    }
    exit
}

try {
    # 5. Verify as Student
    Write-Host "5. Verifying as Student..."
    $myPlan = Invoke-RestMethod -Method Get -Uri "$base/plans/student/my-plan" -Headers @{ Authorization = "Bearer $studentToken" }
    
    if ($myPlan -eq $null) {
        Write-Host "FAILURE: No plan returned for student."
        exit
    }
    
    # Check structure, sometimes it returns the plan directly or wrapped
    $returnedId = if ($myPlan.plan) { $myPlan.plan.id } else { $myPlan.id }
    
    if ($returnedId -eq $planId) {
        Write-Host "SUCCESS: Student has the correct plan assigned."
    }
    else {
        Write-Host "FAILURE: Plan ID mismatch. Expected $planId, got $returnedId"
        Write-Host "Returned Plan: $($myPlan | ConvertTo-Json -Depth 2)"
    }
}
catch {
    Write-Host "ERROR in Verify Student: $_"
    exit
}
