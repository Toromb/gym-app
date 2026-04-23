param()

$base = "lib\src\screens"

# Map of file -> relative import path for constrained_app_bar.dart
$files = @{
  "$base\student\student_plans_list_screen.dart"                          = "../../widgets/constrained_app_bar.dart"
  "$base\student\student_history_screen.dart"                             = "../../widgets/constrained_app_bar.dart"
  "$base\student\profile\profile_progress_screen.dart"                    = "../../../widgets/constrained_app_bar.dart"
  "$base\student\calendar_screen.dart"                                    = "../../widgets/constrained_app_bar.dart"
  "$base\student\muscle_flow_screen.dart"                                 = "../../widgets/constrained_app_bar.dart"
  "$base\shared\plan_details_screen.dart"                                 = "../../widgets/constrained_app_bar.dart"
  "$base\shared\plans_list_screen.dart"                                   = "../../widgets/constrained_app_bar.dart"
  "$base\shared\gym_schedule_screen.dart"                                 = "../../widgets/constrained_app_bar.dart"
  "$base\shared\day_detail_screen.dart"                                   = "../../widgets/constrained_app_bar.dart"
  "$base\shared\user_detail_screen.dart"                                  = "../../widgets/constrained_app_bar.dart"
  "$base\profile_screen.dart"                                             = "../widgets/constrained_app_bar.dart"
  "$base\teacher\student_plans_screen.dart"                               = "../../widgets/constrained_app_bar.dart"
  "$base\teacher\manage_students_screen.dart"                             = "../../widgets/constrained_app_bar.dart"
  "$base\teacher\exercise_detail_screen.dart"                             = "../../widgets/constrained_app_bar.dart"
  "$base\teacher\exercises_list_screen.dart"                              = "../../widgets/constrained_app_bar.dart"
  "$base\teacher\create_plan_screen.dart"                                 = "../../widgets/constrained_app_bar.dart"
  "$base\teacher\create_exercise_screen.dart"                             = "../../widgets/constrained_app_bar.dart"
  "$base\teacher\add_student_screen.dart"                                 = "../../widgets/constrained_app_bar.dart"
  "$base\admin\manage_users_screen.dart"                                  = "../../widgets/constrained_app_bar.dart"
  "$base\admin\manage_equipments_screen.dart"                             = "../../widgets/constrained_app_bar.dart"
  "$base\admin\gym_config_screen.dart"                                    = "../../widgets/constrained_app_bar.dart"
  "$base\admin\edit_user_screen.dart"                                     = "../../widgets/constrained_app_bar.dart"
  "$base\admin\add_user_screen.dart"                                      = "../../widgets/constrained_app_bar.dart"
  "$base\admin\free_training\free_training_editor_screen.dart"            = "../../../widgets/constrained_app_bar.dart"
  "$base\super_admin\super_admin_leads_screen.dart"                       = "../../widgets/constrained_app_bar.dart"
  "$base\super_admin\super_admin_dashboard.dart"                          = "../../widgets/constrained_app_bar.dart"
  "$base\super_admin\platform_stats_screen.dart"                          = "../../widgets/constrained_app_bar.dart"
  "$base\super_admin\gym_admins_screen.dart"                              = "../../widgets/constrained_app_bar.dart"
  "$base\super_admin\gyms_list_screen.dart"                               = "../../widgets/constrained_app_bar.dart"
  "$base\public\terms_screen.dart"                                        = "../../widgets/constrained_app_bar.dart"
  "$base\public\support_screen.dart"                                      = "../../widgets/constrained_app_bar.dart"
  "$base\public\register_with_invite_screen.dart"                         = "../../widgets/constrained_app_bar.dart"
  "$base\public\gym_interest_screen.dart"                                 = "../../widgets/constrained_app_bar.dart"
  "$base\auth\qr_scanner_screen.dart"                                     = "../../widgets/constrained_app_bar.dart"
}

$total = 0
$modified = 0

foreach ($entry in $files.GetEnumerator()) {
  $path = $entry.Key
  $importPath = $entry.Value

  if (-not (Test-Path $path)) {
    Write-Host "SKIP (not found): $path"
    continue
  }

  $total++
  $content = Get-Content $path -Raw -Encoding UTF8

  # Check if AppBar( is present (we only need to modify if it is)
  if ($content -notmatch 'appBar: AppBar\(') {
    Write-Host "SKIP (no AppBar): $path"
    continue
  }

  $original = $content

  # 1. Replace 'appBar: AppBar(' with 'appBar: ConstrainedAppBar('
  $content = $content -replace 'appBar: AppBar\(', 'appBar: ConstrainedAppBar('

  # 2. Add import if not already present
  $importLine = "import '$importPath';"
  if ($content -notmatch [regex]::Escape($importPath)) {
    # Add after the first import line
    $content = $content -replace "(import 'package:flutter/material.dart';)", "`$1`n$importLine"
  }

  if ($content -ne $original) {
    Set-Content $path $content -Encoding UTF8 -NoNewline
    Write-Host "UPDATED: $path"
    $modified++
  } else {
    Write-Host "NO CHANGE: $path"
  }
}

Write-Host ""
Write-Host "Done: $modified/$total files updated."
