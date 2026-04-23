$f = 'lib\src\screens\shared\gym_schedule_screen.dart'
$c = [System.IO.File]::ReadAllText($f)
$before = $c
$pattern = 'color:\s*Theme\.of\(context\)[\s\S]*?\.surface[\s\S]*?\.withOpacity\(0\.9\),\s*(//[^\r\n]*)?\r?\n'
$c = [regex]::Replace($c, $pattern, '')
if ($c -ne $before) {
    [System.IO.File]::WriteAllText($f, $c)
    Write-Host 'UPDATED gym_schedule_screen.dart'
} else {
    Write-Host 'NO MATCH - showing withOpacity lines:'
    $c -split "`r?`n" | Select-String 'withOpacity' | Select-Object -First 5
}
