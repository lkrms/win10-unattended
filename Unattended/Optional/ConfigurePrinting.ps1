$ErrorActionPreference = "Stop"

function ConfigureLprPrinter ($PrinterName, $DriverName, $HostAddress, $DuplexingMode) {
    try {
        Write-Host "Setting up $PrinterName"
        Write-Host "Adding driver"
        Add-PrinterDriver -Name $DriverName
        Write-Host "Adding port"
        try {
            Add-PrinterPort -Name $HostAddress -LprHostAddress $HostAddress -LprQueueName "BINARY_P1" -SNMP 1 -SNMPCommunity "public"
        } catch {
            Write-Host "Error adding port:"
            Write-Host $_
        }
        Write-Host "Adding printer"
        try {
            Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $HostAddress
        } catch {
            Write-Host "Error adding printer:"
            Write-Host $_
        }
        Write-Host "Applying settings"
        Set-PrintConfiguration -PrinterName $PrinterName -PaperSize A4 -DuplexingMode $DuplexingMode
    } catch {
        Write-Host "Error configuring ${PrinterName}:"
        Write-Host $_
    }
}

function RemoveLprPrinter ($PrinterName, $HostAddress) {
    try {
        Write-Host "Removing $PrinterName if present"
        Write-Host "Removing printer"
        try {
            Remove-Printer -Name $PrinterName
        } catch {
            Write-Host "Error removing printer:"
            Write-Host $_
        }
        Write-Host "Removing port"
        try {
            Remove-PrinterPort -Name $HostAddress
        } catch {
            Write-Host "Error removing port:"
            Write-Host $_
        }
    } catch {
        Write-Host "Error removing ${PrinterName}:"
        Write-Host $_
    }
}

RemoveLprPrinter -PrinterName "Brother HL-5450DN (black and white)" `
    -HostAddress "10.10.10.10"

ConfigureLprPrinter -PrinterName "Brother HL-L2375DW (black and white)" `
    -DriverName "Brother HL-L2375DW series" `
    -HostAddress "10.10.10.17" `
    -DuplexingMode TwoSidedLongEdge

ConfigureLprPrinter -PrinterName "Brother HL-L3230CDW (colour)" `
    -DriverName "Brother HL-L3230CDW series" `
    -HostAddress "10.10.10.11" `
    -DuplexingMode OneSided

try {
    (New-Object -ComObject WScript.Network).SetDefaultPrinter("Brother HL-L2375DW (black and white)")
} catch {}
