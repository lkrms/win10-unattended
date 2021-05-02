$ErrorActionPreference = "Stop"

# See: https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10
$packageNames = @(
    # Cortana
    "Microsoft.549981C3F5F10"
    "Microsoft.GetHelp"
    # Microsoft Tips
    "Microsoft.Getstarted"
    # "Office"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MixedReality.Portal"
    # OneNote for Windows 10
    "Microsoft.Office.OneNote"
    # Skype
    "Microsoft.SkypeApp"
    # Microsoft Pay
    "Microsoft.Wallet"
    # Mail and Calendar
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    # Xbox Live in-game experience
    #"Microsoft.Xbox.TCUI"
    # Xbox Console Companion
    #"Microsoft.XboxApp"
    # Xbox Game Bar Plugin
    "Microsoft.XboxGameOverlay"
    # Xbox Game Bar
    #"Microsoft.XboxGamingOverlay"
    # Xbox Identity Provider
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    # Your Phone
    "Microsoft.YourPhone"
    # Groove Music
    "Microsoft.ZuneMusic"
    # Movies & TV
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
