$base = "http://localhost:3000"

# 1. Login Super Admin
$tokenSA = (Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Body (@{email = "superadmin@gym.com"; password = "admin123" } | ConvertTo-Json) -ContentType "application/json").access_token

# 2. Create Gym to Delete
$gym = Invoke-RestMethod -Method Post -Uri "$base/gyms" -Headers @{Authorization = "Bearer $tokenSA" } -Body (@{businessName = "Gym To Delete " + (Get-Random); address = "Addr"; email = "delete@test.com" } | ConvertTo-Json) -ContentType "application/json"
$gymId = $gym.id
Write-Host "Created Gym: $gymId"

# 3. Create Admin in that Gym
$adminEmail = "to_delete_admin$(Get-Random)@test.com"
$user = Invoke-RestMethod -Method Post -Uri "$base/users" -Headers @{Authorization = "Bearer $tokenSA" } -Body (@{email = $adminEmail; password = "password123"; firstName = "Del"; lastName = "User"; role = "admin"; gymId = $gymId } | ConvertTo-Json) -ContentType "application/json"
$userId = $user.id
Write-Host "Created User: $userId"

# 4. Login as that Admin to create Exercise
$tokenAdmin = (Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Body (@{email = $adminEmail; password = "password123" } | ConvertTo-Json) -ContentType "application/json").access_token
$ex = Invoke-RestMethod -Method Post -Uri "$base/exercises" -Headers @{Authorization = "Bearer $tokenAdmin" } -Body (@{name = "Exercise To Delete"; muscleGroup = "Legs" } | ConvertTo-Json) -ContentType "application/json"
$exId = $ex.id
Write-Host "Created Exercise: $exId"

# 5. Delete Gym
Write-Host "Deleting Gym..."
Invoke-RestMethod -Method Delete -Uri "$base/gyms/$gymId" -Headers @{Authorization = "Bearer $tokenSA" }

# 6. Verify Deletion
Write-Host "Verifying Deletion..."

try {
    Invoke-RestMethod -Method Get -Uri "$base/gyms/$gymId" -Headers @{Authorization = "Bearer $tokenSA" }
    Write-Host "FAIL: Gym still exists"
}
catch {
    Write-Host "PASS: Gym deleted query failed (Expected 404/Error)"
}

try {
    $u = Invoke-RestMethod -Method Get -Uri "$base/users/$userId" -Headers @{Authorization = "Bearer $tokenSA" }
    if ($u) { Write-Host "FAIL: User still exists" } else { Write-Host "PASS: User gone (null)" }
}
catch {
    Write-Host "PASS: User deleted query failed"
}

try {
    # Check if exercise exists - as Super Admin we can see all, check if this ID exists
    $allEx = Invoke-RestMethod -Method Get -Uri "$base/exercises" -Headers @{Authorization = "Bearer $tokenSA" }
    $found = $allEx | Where-Object { $_.id -eq $exId }
    if ($found) {
        Write-Host "FAIL: Exercise $exId still exists"
    }
    else {
        Write-Host "PASS: Exercise deleted"
    }
}
catch {
    Write-Host "Error checking exercise: $_"
}
