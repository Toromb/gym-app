$base = "http://localhost:3000"

# 1. Login Super Admin
$tokenSA = (Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Body (@{email = "superadmin@gym.com"; password = "admin123" } | ConvertTo-Json) -ContentType "application/json").access_token

# 2. Create Gym A
$gymA = Invoke-RestMethod -Method Post -Uri "$base/gyms" -Headers @{Authorization = "Bearer $tokenSA" } -Body (@{businessName = "Gym A " + (Get-Random); address = "Addr A"; email = "gyma@test.com" } | ConvertTo-Json) -ContentType "application/json"
Write-Host "Created Gym A: $($gymA.id)"

# 3. Create Admin A
$adminAEmail = "adminA$(Get-Random)@test.com"
Invoke-RestMethod -Method Post -Uri "$base/users" -Headers @{Authorization = "Bearer $tokenSA" } -Body (@{email = $adminAEmail; password = "password123"; firstName = "Admin"; lastName = "A"; role = "admin"; gymId = $gymA.id } | ConvertTo-Json) -ContentType "application/json"
$tokenAdminA = (Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Body (@{email = $adminAEmail; password = "password123" } | ConvertTo-Json) -ContentType "application/json").access_token

# 4. Create Gym B
$gymB = Invoke-RestMethod -Method Post -Uri "$base/gyms" -Headers @{Authorization = "Bearer $tokenSA" } -Body (@{businessName = "Gym B " + (Get-Random); address = "Addr B"; email = "gymb@test.com" } | ConvertTo-Json) -ContentType "application/json"
Write-Host "Created Gym B: $($gymB.id)"

# 5. Create Admin B
$adminBEmail = "adminB$(Get-Random)@test.com"
Invoke-RestMethod -Method Post -Uri "$base/users" -Headers @{Authorization = "Bearer $tokenSA" } -Body (@{email = $adminBEmail; password = "password123"; firstName = "Admin"; lastName = "B"; role = "admin"; gymId = $gymB.id } | ConvertTo-Json) -ContentType "application/json"
$tokenAdminB = (Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Body (@{email = $adminBEmail; password = "password123" } | ConvertTo-Json) -ContentType "application/json").access_token

# 6. Admin A creates Exercise
$exA = Invoke-RestMethod -Method Post -Uri "$base/exercises" -Headers @{Authorization = "Bearer $tokenAdminA" } -Body (@{name = "Squat A"; muscleGroup = "Legs" } | ConvertTo-Json) -ContentType "application/json"
Write-Host "Admin A Created Exercise: $($exA.id)"

# 7. Admin A lists Exercises
$listA = Invoke-RestMethod -Method Get -Uri "$base/exercises" -Headers @{Authorization = "Bearer $tokenAdminA" }
Write-Host "Admin A sees $($listA.length) exercises."

# 8. Admin B lists Exercises
$listB = Invoke-RestMethod -Method Get -Uri "$base/exercises" -Headers @{Authorization = "Bearer $tokenAdminB" }
Write-Host "Admin B sees $($listB.length) exercises."

# 9. Admin B creates Exercise
$exB = Invoke-RestMethod -Method Post -Uri "$base/exercises" -Headers @{Authorization = "Bearer $tokenAdminB" } -Body (@{name = "Squat B"; muscleGroup = "Legs" } | ConvertTo-Json) -ContentType "application/json"
Write-Host "Admin B Created Exercise: $($exB.id)"

# 10. Verify Isolation
$listA2 = Invoke-RestMethod -Method Get -Uri "$base/exercises" -Headers @{Authorization = "Bearer $tokenAdminA" }
$listB2 = Invoke-RestMethod -Method Get -Uri "$base/exercises" -Headers @{Authorization = "Bearer $tokenAdminB" }

if ($listA2.length -eq 1 -and $listA2[0].name -eq "Squat A") {
    Write-Host "PASS: Admin A only sees own exercises."
}
else {
    Write-Host "FAIL: Admin A sees $($listA2.length) exercises."
}

if ($listB2.length -eq 1 -and $listB2[0].name -eq "Squat B") {
    Write-Host "PASS: Admin B only sees own exercises."
}
else {
    Write-Host "FAIL: Admin B sees $($listB2.length) exercises."
}
