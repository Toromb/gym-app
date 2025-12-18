$base = "http://localhost:3000"

# 1. Login Super Admin to create Gym
$tokenSA = (Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Body (@{email = "superadmin@gym.com"; password = "admin123" } | ConvertTo-Json) -ContentType "application/json").access_token
$gym = Invoke-RestMethod -Method Post -Uri "$base/gyms" -Headers @{Authorization = "Bearer $tokenSA" } -Body (@{businessName = "ProfIsoGym"; address = "Addr"; email = "p@iso.com" } | ConvertTo-Json) -ContentType "application/json"
$gymId = $gym.id
Write-Host "Gym Created: $gymId"

# 2. Create Admin for Gym
$adminEmail = "admin_iso_$(Get-Random)@test.com"
Invoke-RestMethod -Method Post -Uri "$base/users" -Headers @{Authorization = "Bearer $tokenSA" } -Body (@{email = $adminEmail; password = "password123"; firstName = "Admin"; lastName = "Iso"; role = "admin"; gymId = $gymId } | ConvertTo-Json) -ContentType "application/json" | Out-Null
$tokenAdmin = (Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Body (@{email = $adminEmail; password = "password123" } | ConvertTo-Json) -ContentType "application/json").access_token

# 3. Create Professor
$profEmail = "prof_iso_$(Get-Random)@test.com"
$prof = Invoke-RestMethod -Method Post -Uri "$base/users" -Headers @{Authorization = "Bearer $tokenAdmin" } -Body (@{email = $profEmail; password = "password123"; firstName = "Prof"; lastName = "Iso"; role = "profe" } | ConvertTo-Json) -ContentType "application/json"
$profId = $prof.id
Write-Host "Professor Created: $profId ($profEmail)"

# 4. Create Student Assigned to Professor (Should see)
$studentMineEmail = "stud_mine_$(Get-Random)@test.com"
Invoke-RestMethod -Method Post -Uri "$base/users" -Headers @{Authorization = "Bearer $tokenAdmin" } -Body (@{email = $studentMineEmail; password = "password123"; firstName = "My"; lastName = "Student"; role = "alumno"; professorId = $profId } | ConvertTo-Json) -ContentType "application/json" | Out-Null

# 5. Create Student NOT Assigned (Should NOT see)
$studentOtherEmail = "stud_other_$(Get-Random)@test.com"
Invoke-RestMethod -Method Post -Uri "$base/users" -Headers @{Authorization = "Bearer $tokenAdmin" } -Body (@{email = $studentOtherEmail; password = "password123"; firstName = "Other"; lastName = "Student"; role = "alumno" } | ConvertTo-Json) -ContentType "application/json" | Out-Null

# 6. Create Another Admin (Should NOT see)
$adminOtherEmail = "admin2_iso_$(Get-Random)@test.com"
Invoke-RestMethod -Method Post -Uri "$base/users" -Headers @{Authorization = "Bearer $tokenSA" } -Body (@{email = $adminOtherEmail; password = "password123"; firstName = "Admin"; lastName = "Other"; role = "admin"; gymId = $gymId } | ConvertTo-Json) -ContentType "application/json" | Out-Null


# 7. Login as Professor and List Users
Write-Host "Logging in as Professor..."
$tokenProf = (Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Body (@{email = $profEmail; password = "password123" } | ConvertTo-Json) -ContentType "application/json").access_token

Write-Host "Fetching Users..."
$users = Invoke-RestMethod -Method Get -Uri "$base/users" -Headers @{Authorization = "Bearer $tokenProf" }

Write-Host "--- Users Seen by Professor ---"
$users | ForEach-Object { 
    Write-Host "$($_.firstName) $($_.lastName) [$($_.role)] - Prof: $($_.professor.id)" 
}

# Verification
$seenOther = $users | Where-Object { $_.email -eq $studentOtherEmail }
$seenAdmin = $users | Where-Object { $_.role -eq 'admin' }

if ($seenOther) { Write-Host "FAIL: Seen unassigned student" }
if ($seenAdmin) { Write-Host "FAIL: Seen Admin" }
if (-not $seenOther -and -not $seenAdmin) { Write-Host "PASS: Only assigned students seen" }
