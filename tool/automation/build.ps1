param(
  [Parameter(Mandatory=$true)][string]$FlutterRoot,
  [Parameter(Mandatory=$true)][string]$CMake,
  [ValidateSet('Debug', 'Profile')][string]$Configuration = 'Debug',
  [ValidateSet('tool/automation/main.dart','tool/automation/debug_window.dart')][string]$Target = 'tool/automation/main.dart',
  [string]$SkillRoot = "$env:USERPROFILE/.codex/skills/flutter-ui-automation"
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Push-Location $projectRoot
try {
  foreach ($required in @("$FlutterRoot/bin/flutter.bat", $CMake,
      "$SkillRoot/SKILL.md", "$SkillRoot/tools/window_capture/CMakeLists.txt")) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing prerequisite: $required" }
  }
  & "$FlutterRoot/bin/flutter.bat" pub get
  if ($LASTEXITCODE -ne 0) { throw 'pub get failed' }
  & $CMake -S "$SkillRoot/tools/window_capture" -B build/flutter-ui-automation/window-capture -G 'Visual Studio 18 2026' -A x64
  if ($LASTEXITCODE -ne 0) { throw 'Native helper configure failed' }
  & $CMake --build build/flutter-ui-automation/window-capture --config Release
  if ($LASTEXITCODE -ne 0) { throw 'Native helper build failed' }
  $mode = '--' + $Configuration.ToLowerInvariant()
  & "$FlutterRoot/bin/flutter.bat" build windows $mode --no-pub --config-only --target $Target
  if ($LASTEXITCODE -ne 0) { throw 'Flutter test configuration failed' }
  & $CMake -S windows -B build/automation-windows/x64 -G 'Visual Studio 18 2026' -A x64 -DBOORUFLOW_UI_AUTOMATION=ON
  if ($LASTEXITCODE -ne 0) { throw 'Test runner configure failed' }
  & $CMake --build build/automation-windows/x64 --config $Configuration --target INSTALL
  if ($LASTEXITCODE -ne 0) { throw 'Test runner build failed' }
} finally {
  Pop-Location
}
