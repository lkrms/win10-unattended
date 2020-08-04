$ErrorActionPreference = "Stop"

$packageNames = @(
    "Microsoft.549981C3F5F10"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MixedReality.Portal"
    "Microsoft.Office.OneNote"
    "Microsoft.SkypeApp"
    "Microsoft.Wallet"
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
)

try {
    $packages = Get-ProvisionedAppxPackage -Online |
    Where-Object DisplayName -CIn $packageNames

    if ($packages) {
        $missing = $packageNames.Count - $packages.Count
        Write-Host "Removing provisioned packages:"
        Write-Host -NoNewline ($packages |
            Format-Table -HideTableHeaders -Property DisplayName |
            Out-String)
        Write-Host "Total: $($packages.Count)" `
            "($($missing) missing or previously removed)"
        $packages | Remove-ProvisionedAppxPackage -Online
    } else {
        Write-Host "No provisioned packages to remove"
    }
} catch {
    Write-Host "Error removing provisioned packages:"
    Write-Host $_
}
