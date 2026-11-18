# يبني التطبيق ويثبّته على الجوال الموصول (debug) ويتصل بالخادم المحلي
# الاستخدام:
#   powershell -ExecutionPolicy Bypass -File scripts\run-phone.ps1          # flutter run (سجلات + hot reload)
#   ... run-phone.ps1 -Apk                                                   # يبني apk debug ويثبّته فقط
#   ... run-phone.ps1 -Phone 192.168.0.100:34279                            # جوال لاسلكي (Wireless debugging)
#   ... run-phone.ps1 -Lan                                                   # بدل adb reverse: IP الكمبيوتر على الشبكة
#   ... run-phone.ps1 -Reverse                                               # إجبار adb reverse حتى لو قاعدة الجدار موجودة
#   ... run-phone.ps1 -StatementUrl https://x/statement/                     # عنوان صفحة كشف الحساب (افتراضياً run-statement.ps1 عبر adb reverse 8092)
# ملاحظة: adb reverse يضيع عند انقطاع التصحيح اللاسلكي فتبقى الحركات «بانتظار المزامنة».
# الحل الثابت: شغّل scripts\open-firewall.ps1 مرة واحدة (كمسؤول) — بعدها يُستخدم IP الكمبيوتر تلقائياً.
param([switch]$Apk, [switch]$Lan, [switch]$Reverse, [string]$Device, [string]$Phone, [string]$StatementUrl = '')
. "$PSScriptRoot\_common.ps1"
Connect-WirelessPhone $Phone
if ($Phone -and -not $Device) { $Device = $Phone }

$st = Get-SupabaseStatus
$anon = $st.ANON_KEY
$devs = @(Get-AndroidDevices)
if ($devs.Count -eq 0) { throw 'لا يوجد جوال موصول — وصّل الجوال بـ USB وفعّل USB debugging ووافق على نافذة السماح' }
if (-not $Device) { $Device = $devs[0] }

if (-not $Lan -and -not $Reverse -and (Get-NetFirewallRule -DisplayName $FirewallRuleName -ErrorAction SilentlyContinue)) {
  $Lan = $true
  Write-Host 'قاعدة الجدار الناري موجودة ← وضع الشبكة المحلية (لا يتأثر بانقطاع adb)' -ForegroundColor Green
}

if ($Lan) {
  $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' -and $_.IPAddress -notlike '169.*' } | Select-Object -First 1).IPAddress
  if (-not $ip) { throw 'تعذّر معرفة IP الكمبيوتر' }
  $url = "http://${ip}:54321"
  Write-Host "يستخدم $url — إن لم يتصل شغّل مرة واحدة كمسؤول: scripts\open-firewall.ps1" -ForegroundColor Yellow
} else {
  & (Get-Adb) -s $Device reverse tcp:54321 tcp:54321 | Out-Null
  $url = 'http://127.0.0.1:54321'
  Write-Warning 'وضع adb reverse: إذا انقطع التصحيح اللاسلكي لن تتزامن الحركات حتى تعيد تشغيل هذا السكربت. للحل الثابت: scripts\open-firewall.ps1'
}

# صفحة كشف الحساب (scripts/run-statement.ps1 على المنفذ 8092) — للتجربة من نفس الجوال
if (-not $StatementUrl) {
  & (Get-Adb) -s $Device reverse tcp:8092 tcp:8092 | Out-Null
  $StatementUrl = 'http://127.0.0.1:8092/statement/'
}
$defines = @("--dart-define=SUPABASE_URL=$url", "--dart-define=SUPABASE_ANON_KEY=$anon", "--dart-define=STATEMENT_BASE_URL=$StatementUrl")
Set-Location (Join-Path $Root 'app')
Write-Host "الجهاز: $Device   الخادم: $url" -ForegroundColor Cyan

if ($Apk) {
  flutter build apk --debug --target-platform android-arm64 @defines
  if ($LASTEXITCODE -ne 0) { throw 'فشل البناء' }
  & (Get-Adb) -s $Device install -r build\app\outputs\flutter-apk\app-debug.apk
  & (Get-Adb) -s $Device shell am start -n app.ajil.ajil/.MainActivity | Out-Null
  Write-Host 'تم التثبيت والتشغيل. السجلات: flutter logs' -ForegroundColor Green
} else {
  flutter run -d $Device --debug @defines
}
