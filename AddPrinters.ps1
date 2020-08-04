$ErrorActionPreference = "Stop"

Write-Host "Configuring printers"

try {
    Add-PrinterDriver -Name "Brother HL-5450DN series"
    Add-PrinterPort -Name "10.10.10.10" -LprHostAddress "10.10.10.10" -LprQueueName "BINARY_P1" -SNMP 1 -SNMPCommunity "public"
    Add-Printer -Name "Brother HL-5450DN (black and white)" -DriverName "Brother HL-5450DN series" -PortName "10.10.10.10"
    Set-PrintConfiguration -PrinterName "Brother HL-5450DN (black and white)" -PaperSize A4 -DuplexingMode TwoSidedLongEdge
} catch {
    Write-Host "Error adding Brother HL-5450DN:"
    Write-Host $_
}

try {
    Add-PrinterDriver -Name "Brother HL-L3230CDW series"
    Add-PrinterPort -Name "10.10.10.11" -LprHostAddress "10.10.10.11" -LprQueueName "BINARY_P1" -SNMP 1 -SNMPCommunity "public"
    Add-Printer -Name "Brother HL-L3230CDW (colour)" -DriverName "Brother HL-L3230CDW series" -PortName "10.10.10.11"
    Set-PrintConfiguration -PrinterName "Brother HL-L3230CDW (colour)" -PaperSize A4 -DuplexingMode OneSided
} catch {
    Write-Host "Error adding Brother HL-L3230CDW:"
    Write-Host $_
}

try {
    (New-Object -ComObject WScript.Network).SetDefaultPrinter("Brother HL-5450DN (black and white)")
} catch {
    Write-Host "Error setting default printer:"
    Write-Host $_
}
