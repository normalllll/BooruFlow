param([string]$GeneratorRoot = "$PSScriptRoot/icon_font", [string]$Dart = 'dart')
$ErrorActionPreference = 'Stop'
$appRoot = Split-Path $PSScriptRoot -Parent
$python = Join-Path $GeneratorRoot '.venv/Scripts/python.exe'
if (-not (Test-Path -LiteralPath $python)) { throw 'Prepare the fixed tool environment first; see tool/README.md.' }
Push-Location $appRoot
try {
  & $python "$GeneratorRoot/generate.py" build --source tool/icons/svg --map tool/icons/codepoints.csv --family BooruFlowIcons --class-name BooruFlowIcons --font assets/fonts/BooruFlowIcons.ttf --dart lib/app/icons.g.dart --license tool/icons/LICENSE --review build/icon-review
  if ($LASTEXITCODE -ne 0) { throw 'Icon generation failed' }
  & $Dart format lib/app/icons.g.dart
  if ($LASTEXITCODE -ne 0) { throw 'Generated Dart formatting failed' }
  Copy-Item -LiteralPath tool/icons/LICENSE -Destination assets/fonts/LICENSE-Lucide.txt
} finally { Pop-Location }
