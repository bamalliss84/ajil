# ينشئ مدير منصة على Supabase المحلي (مستخدم Auth + صف في app.platform_admins)
# الاستخدام:
#   powershell -ExecutionPolicy Bypass -File scripts/create-platform-admin.ps1 -Email admin@ajil.local -Password '...' -Name 'مدير المنصة'
# للتطوير المحلي فقط. في الإنتاج: من لوحة Supabase كما في web/README.md
param(
  [Parameter(Mandatory = $true)][string]$Email,
  [Parameter(Mandatory = $true)][string]$Password,
  [string]$Name = 'مدير المنصة'
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$ErrorActionPreference = 'Continue'   # npx يكتب ملاحظات على stderr
$raw = (cmd /c "npx supabase status -o json 2>nul") -join "`n"
$ErrorActionPreference = 'Stop'
$st = $raw.Substring($raw.IndexOf('{')) | ConvertFrom-Json
$headers = @{ apikey = $st.SERVICE_ROLE_KEY; Authorization = "Bearer $($st.SERVICE_ROLE_KEY)" }

$body = @{ email = $Email; password = $Password; email_confirm = $true } | ConvertTo-Json
try {
  $user = Invoke-RestMethod -Method Post -Uri "$($st.API_URL)/auth/v1/admin/users" -Headers $headers `
    -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body))
  $id = $user.id
} catch {
  # موجود مسبقاً؟ نبحث عنه
  $list = Invoke-RestMethod -Uri "$($st.API_URL)/auth/v1/admin/users?per_page=1000" -Headers $headers
  $id = ($list.users | Where-Object { $_.email -eq $Email.ToLower() }).id
  if (-not $id) { throw }
}

$sql = "insert into app.platform_admins (auth_user_id, name) values ('$id', '$($Name -replace "'", "''")') on conflict (auth_user_id) do update set name = excluded.name;"
$env:MSYS_NO_PATHCONV = '1'
docker exec supabase_db_ajil psql -U postgres -v ON_ERROR_STOP=1 -c $sql | Out-Null
Write-Host "platform admin ready: $Email ($id)"
