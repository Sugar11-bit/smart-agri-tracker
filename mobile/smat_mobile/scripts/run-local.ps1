param(
    [string]$DeviceId = 'emulator-5554',
    [string]$Flutter = 'F:\Development\flutter\bin\flutter.bat',
    [string]$Adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe",
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if (!(Test-Path -LiteralPath $Adb)) { throw "Không tìm thấy adb: $Adb" }
if (!(Test-Path -LiteralPath $Flutter)) { throw "Không tìm thấy Flutter: $Flutter" }
$state = & $Adb -s $DeviceId get-state 2>$null
if ($LASTEXITCODE -ne 0 -or $state -ne 'device') { throw "Hãy mở Android và kiểm tra DeviceId ($DeviceId)." }
# /me must reject anonymous requests; do not need or store credentials.
try {
    Invoke-WebRequest 'http://127.0.0.1:8080/api/v1/auth/me' -UseBasicParsing -TimeoutSec 12 | Out-Null
    throw 'API /auth/me không yêu cầu xác thực. Kiểm tra cấu hình Backend.'
} catch {
    if ($null -eq $_.Exception.Response -or [int]$_.Exception.Response.StatusCode -ne 401) {
        throw "Backend local chưa sẵn sàng hoặc sai cấu hình: $($_.Exception.Message)"
    }
}
& $Adb -s $DeviceId reverse tcp:8080 tcp:8080
if ($LASTEXITCODE -ne 0) { throw 'Không thiết lập được adb reverse.' }
Write-Host 'Backend sẵn sàng; Android đã được kết nối tới cổng 8080.'
if (!$CheckOnly) {
    & $Flutter run --no-pub -d $DeviceId --dart-define=API_BASE_URL=http://127.0.0.1:8080
    if ($LASTEXITCODE -ne 0) { throw 'Flutter chạy thất bại. Kiểm tra thông báo phía trên.' }
}
