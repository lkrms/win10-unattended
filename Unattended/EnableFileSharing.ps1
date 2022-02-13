$ErrorActionPreference = "Stop"

try {
    Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True -Profile Private
} catch {
    Write-Host "Error enabling file sharing:"
    Write-Host $_
}
