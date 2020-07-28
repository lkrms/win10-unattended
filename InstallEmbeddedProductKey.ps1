$service = Get-WmiObject -Query "select * from SoftwareLicensingService"
if ($key = $service.OA3xOriginalProductKey) {
    Write-Host "Installing original product key:" $key
    $service.InstallProductKey($key)
} else {
    Write-Host "No OEM product key found"
}
