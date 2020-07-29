$ErrorActionPreference = "Stop"

Write-Host "Setting network category to Private for all Public connection profiles"
try {
    Get-NetConnectionProfile -NetworkCategory Public |
    Set-NetConnectionProfile -NetworkCategory Private
} catch {
    Write-Host "No Public connection profiles to change"
}
