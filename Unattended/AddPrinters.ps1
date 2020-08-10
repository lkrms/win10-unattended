$ErrorActionPreference = "Stop"

Write-Host "Configuring printers"

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

ConfigureLprPrinter -PrinterName "Brother HL-5450DN (black and white)" `
    -DriverName "Brother HL-5450DN series" `
    -HostAddress "10.10.10.10" `
    -DuplexingMode TwoSidedLongEdge

ConfigureLprPrinter -PrinterName "Brother HL-L3230CDW (colour)" `
    -DriverName "Brother HL-L3230CDW series" `
    -HostAddress "10.10.10.11" `
    -DuplexingMode OneSided

try {
    (New-Object -ComObject WScript.Network).SetDefaultPrinter("Brother HL-5450DN (black and white)")
} catch {}
