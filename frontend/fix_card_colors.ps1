param()

# Helper: replace a multi-line block in a file using regex
function ReplaceInFile($path, $pattern, $replacement) {
    if (-not (Test-Path $path)) { Write-Host "NOT FOUND: $path"; return }
    $content = [System.IO.File]::ReadAllText($path)
    $before = $content
    $content = [regex]::Replace($content, $pattern, $replacement)
    if ($content -ne $before) {
        [System.IO.File]::WriteAllText($path, $content)
        Write-Host "UPDATED: $path"
    } else {
        Write-Host "NO MATCH: $path for pattern: $($pattern.Substring(0,[Math]::Min(60,$pattern.Length)))"
    }
}

# ─────────────────────────────────────────────────────────────────
# Pattern that matches the colorScheme.surface.withOpacity card color
# (works for both single-line and multi-line formatting)
$surfaceColorPattern = '\bcolor:\s*Theme\.of\(context\)[\s\S]*?\.surface[\s\S]*?\.withOpacity\(0\.9\),\r?\n'

# ─────────────────────────────────────────────────────────────────
# 1. student_plans_list_screen.dart
ReplaceInFile "lib\src\screens\student\student_plans_list_screen.dart" $surfaceColorPattern ""

# ─────────────────────────────────────────────────────────────────
# 2. gym_schedule_screen.dart (2 occurrences — AllowMultiple)
$f = "lib\src\screens\shared\gym_schedule_screen.dart"
$c = [System.IO.File]::ReadAllText($f)
$before = $c
$c = [regex]::Replace($c, $surfaceColorPattern, "")
if ($c -ne $before) { [System.IO.File]::WriteAllText($f, $c); Write-Host "UPDATED: $f" }
else { Write-Host "NO MATCH: $f" }

# ─────────────────────────────────────────────────────────────────
# 3. profile_progress_screen.dart
# Remove surface color overrides from Card widgets
$f = "lib\src\screens\student\profile\profile_progress_screen.dart"
$c = [System.IO.File]::ReadAllText($f)
$before = $c
$c = [regex]::Replace($c, $surfaceColorPattern, "")

# Also fix _buildUnifiedCard Container: replace cardColor.withOpacity with AppColors.cardSurface
$c = $c -replace 'color:\s*Theme\.of\(context\)\.cardColor\.withOpacity\(0\.9\),', 'color: Theme.of(context).brightness == Brightness.light ? const Color(0xFFD6E8FA) : Theme.of(context).cardColor,'

if ($c -ne $before) { [System.IO.File]::WriteAllText($f, $c); Write-Host "UPDATED: $f" }
else { Write-Host "NO MATCH: $f" }

# ─────────────────────────────────────────────────────────────────
# 4. profile_screen.dart
# Remove surface color from _buildSectionCard
$f = "lib\src\screens\profile_screen.dart"
$c = [System.IO.File]::ReadAllText($f)
$before = $c
$c = [regex]::Replace($c, $surfaceColorPattern, "")

# Fix floating name text — add drop shadow
# The name Text currently uses theme's headlineSmall (dark on light bg, invisible on dark bg image)
# Replace with BackgroundStyles.fromTheme(...)
$oldName = "Text\(_user!\.name,\s*\r?\n\s*style: Theme\.of\(context\)\s*\r?\n\s*\.textTheme\s*\r?\n\s*\.headlineSmall\s*\r?\n\s*\?\.copyWith\(fontWeight: FontWeight\.bold\)\),"
$newName = "Text(_user!.name,
            style: BackgroundStyles.fromTheme(
              Theme.of(context).textTheme.headlineSmall,
            ).copyWith(fontWeight: FontWeight.bold)),"
$c = [regex]::Replace($c, $oldName, $newName)

# Add BackgroundStyles import if not present
if ($c -notmatch "background_styles\.dart") {
    $c = $c -replace "(import 'package:flutter/material\.dart';)", "`$1`nimport 'theme/background_styles.dart';"
}

if ($c -ne $before) { [System.IO.File]::WriteAllText($f, $c); Write-Host "UPDATED: $f" }
else { Write-Host "NO MATCH: $f" }

Write-Host "`nDone."
