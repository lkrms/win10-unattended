$ErrorActionPreference = "Stop"

Write-Host "Configuring printers"

try {
    Write-Host "Setting up Brother HL-5450DN"
    Write-Host "Adding driver"
    Add-PrinterDriver -Name "Brother HL-5450DN series"
    Write-Host "Adding port"
    try {
        Add-PrinterPort -Name "10.10.10.10" -LprHostAddress "10.10.10.10" -LprQueueName "BINARY_P1" -SNMP 1 -SNMPCommunity "public"
    } catch {
        Write-Host "Error adding port:"
        Write-Host $_
    }
    Write-Host "Adding printer"
    try {
        Add-Printer -Name "Brother HL-5450DN (black and white)" -DriverName "Brother HL-5450DN series" -PortName "10.10.10.10"
    } catch {
        Write-Host "Error adding printer:"
        Write-Host $_
    }
    Write-Host "Applying settings"
    Set-PrintConfiguration -PrinterName "Brother HL-5450DN (black and white)" -PaperSize A4 -DuplexingMode TwoSidedLongEdge
} catch {
    Write-Host "Error configuring Brother HL-5450DN:"
    Write-Host $_
}

try {
    Write-Host "Setting up Brother HL-L3230CDW"
    Write-Host "Adding driver"
    Add-PrinterDriver -Name "Brother HL-L3230CDW series"
    Write-Host "Adding port"
    try {
        Add-PrinterPort -Name "10.10.10.11" -LprHostAddress "10.10.10.11" -LprQueueName "BINARY_P1" -SNMP 1 -SNMPCommunity "public"
    } catch {
        Write-Host "Error adding port:"
        Write-Host $_
    }
    Write-Host "Adding printer"
    try {
        Add-Printer -Name "Brother HL-L3230CDW (colour)" -DriverName "Brother HL-L3230CDW series" -PortName "10.10.10.11"
    } catch {
        Write-Host "Error adding printer:"
        Write-Host $_
    }
    Write-Host "Applying settings"
    Set-PrintConfiguration -PrinterName "Brother HL-L3230CDW (colour)" -PaperSize A4 -DuplexingMode OneSided
} catch {
    Write-Host "Error configuring Brother HL-L3230CDW:"
    Write-Host $_
}

try {
    (New-Object -ComObject WScript.Network).SetDefaultPrinter("Brother HL-5450DN (black and white)")
} catch {}
