# Copies the CET mod into the game. Run from the repo root in PowerShell:
#   .\tools\install.ps1
#   .\tools\install.ps1 -GamePath "D:\Games\Cyberpunk 2077"
param(
  [string]$GamePath = "C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077"
)

$mods = Join-Path $GamePath "bin\x64\plugins\cyber_engine_tweaks\mods"
if (-not (Test-Path $mods)) {
  Write-Error "CET mods folder not found at $mods. Is Cyber Engine Tweaks installed?"
  exit 1
}

$target = Join-Path $mods "cp-poser"
New-Item -ItemType Directory -Force -Path $target | Out-Null
# Saved scenes and probe output live in the game copy; never overwrite them.
robocopy "cet\poser" $target /E /XD scenes /XF probe-output.txt /NFL /NDL /NJH /NJS | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $target "scenes") | Out-Null
Write-Host "Installed to $target"
