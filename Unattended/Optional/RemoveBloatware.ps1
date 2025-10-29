$ErrorActionPreference = "Stop"

# See https://learn.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update
$packageNames = @(
    "aimgr"
    "Clipchamp.Clipchamp"
    "Microsoft.549981C3F5F10" # Cortana
    "Microsoft.BingNews"
    "Microsoft.BingSearch"
    #"Microsoft.BingWeather"
    "Microsoft.Copilot"
    "Microsoft.Edge.GameAssist"
    "Microsoft.GamingApp"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted" # Microsoft Tips
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.MixedReality.Portal"
    "Microsoft.Office.OneNote"
    "Microsoft.OneConnect"
    "Microsoft.OneDriveSync" # Remove if not installing for all users
    "Microsoft.OutlookForWindows" # New Outlook
    "Microsoft.People"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.SkypeApp"
    "Microsoft.Todos"
    "Microsoft.Wallet" # Microsoft Pay
    "microsoft.windowscommunicationsapps" # Mail and Calendar (deprecated)
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
    "MicrosoftCorporationII.MicrosoftFamily"
    #"MSTeams" # Uncomment if not using Teams (no machine-wide installer exists)
)

try {
    $packages = Get-ProvisionedAppxPackage -Online |
        Where-Object DisplayName -CIn $packageNames

    if ($packages) {
        Write-Host "Removing provisioned packages:"
        Write-Host -NoNewline ($packages |
                Format-Table -HideTableHeaders -Property DisplayName |
                Out-String)
        Write-Host "Total: $($packages.Count)"
        $packages | Remove-ProvisionedAppxPackage -Online
    } else {
        Write-Host "No provisioned packages to remove"
    }

    $packages = Get-AppxPackage -AllUsers |
        Where-Object Name -CIn $packageNames

    if ($packages) {
        Write-Host "Removing installed packages:"
        Write-Host -NoNewline ($packages |
                Format-Table -HideTableHeaders -Property Name |
                Out-String)
        Write-Host "Total: $($packages.Count)"
        $packages | Remove-AppxPackage -AllUsers
    } else {
        Write-Host "No installed packages to remove"
    }
} catch {
    Write-Host "Error removing packages:"
    Write-Host $_
}
