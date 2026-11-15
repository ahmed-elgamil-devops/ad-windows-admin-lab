# Collects hardware and software inventory from this PC (or a list of
# domain PCs with -ComputerName) and appends it to an asset CSV.
param(
    [string[]] $ComputerName = $env:COMPUTERNAME,
    [string]   $OutFile      = '.\asset-inventory.csv'
)

foreach ($pc in $ComputerName) {
    try {
        $cs   = Get-CimInstance Win32_ComputerSystem -ComputerName $pc
        $bios = Get-CimInstance Win32_BIOS -ComputerName $pc
        $os   = Get-CimInstance Win32_OperatingSystem -ComputerName $pc
        $cpu  = Get-CimInstance Win32_Processor -ComputerName $pc | Select-Object -First 1
        $disk = Get-CimInstance Win32_LogicalDisk -ComputerName $pc -Filter "DeviceID='C:'"

        [pscustomobject]@{
            Date         = Get-Date -Format yyyy-MM-dd
            Computer     = $cs.Name
            Manufacturer = $cs.Manufacturer
            Model        = $cs.Model
            SerialNumber = $bios.SerialNumber
            CPU          = $cpu.Name
            RAM_GB       = [math]::Round($cs.TotalPhysicalMemory / 1GB)
            Disk_C_GB    = [math]::Round($disk.Size / 1GB)
            OS           = "$($os.Caption) $($os.Version)"
            LastUser     = $cs.UserName
        } | Export-Csv -Path $OutFile -Append -NoTypeInformation
        Write-Host "Added $pc" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not reach $pc : $($_.Exception.Message)"
    }
}
