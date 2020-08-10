$ErrorActionPreference = "Stop"

try {
    Get-NetConnectionProfile -NetworkCategory Public |
    Set-NetConnectionProfile -NetworkCategory Private
} catch {
    Write-Host "No Public connection profiles to change"
}
