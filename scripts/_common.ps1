# أدوات مشتركة لسكربتات التطوير
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$DbContainer = 'supabase_db_ajil'

function Get-Adb {
  $sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
  $adb = Join-Path $sdk 'platform-tools\adb.exe'
  if (-not (Test-Path $adb)) { throw "adb غير موجود في $adb — ثبّت Android SDK Platform-Tools" }
  return $adb
}

function Get-AndroidDevices {
  $adb = Get-Adb
  & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' } | ForEach-Object { ($_ -split "`t")[0] }
}

function Get-SupabaseStatus {
  Push-Location $Root
  # PowerShell 5.1 يعامل stderr الأوامر الخارجية كخطأ عند Stop — نخففه هنا مؤقتاً
  $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { $json = (npx supabase status -o json 2>$null | Out-String) } finally { $ErrorActionPreference = $prev; Pop-Location }
  $json = $json.Substring([Math]::Max(0, $json.IndexOf('{')))
  if (-not $json) { throw 'Supabase غير مشغّل — شغّل scripts\dev-up.ps1 أولاً' }
  return $json | ConvertFrom-Json
}

function Set-AdbReverse {
  $adb = Get-Adb
  $devs = @(Get-AndroidDevices)
  if ($devs.Count -eq 0) { Write-Warning 'لا يوجد جوال موصول (adb devices فارغ) — وصّل الجوال وفعّل USB debugging'; return $false }
  foreach ($d in $devs) {
    & $adb -s $d reverse tcp:54321 tcp:54321 | Out-Null
    Write-Host "adb reverse tcp:54321 ← $d" -ForegroundColor Green
  }
  return $true
}
