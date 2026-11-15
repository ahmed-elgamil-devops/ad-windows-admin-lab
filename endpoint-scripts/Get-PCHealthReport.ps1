# Quick health report for a Windows PC: uptime, CPU, memory, disk space,
# pending reboot, Defender status and failed services. Saves an HTML report.
$cs   = Get-CimInstance Win32_ComputerSystem
$os   = Get-CimInstance Win32_OperatingSystem
$cpu  = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
$memUsedPct = [math]::Round((1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 1)
$uptime = (Get-Date) - $os.LastBootUpTime

$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    [pscustomobject]@{
        Drive   = $_.DeviceID
        SizeGB  = [math]::Round($_.Size / 1GB, 1)
        FreeGB  = [math]::Round($_.FreeSpace / 1GB, 1)
        FreePct = [math]::Round($_.FreeSpace / $_.Size * 100, 1)
    }
}

$pendingReboot = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
$defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
$stopped  = Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' } | Select-Object Name, DisplayName

$summary = [pscustomobject]@{
    Computer        = $cs.Name
    Model           = $cs.Model
    OS              = $os.Caption
    UptimeDays      = [math]::Round($uptime.TotalDays, 1)
    CPUPercent      = $cpu
    MemoryUsedPct   = $memUsedPct
    PendingReboot   = $pendingReboot
    DefenderEnabled = $defender.AntivirusEnabled
    SignaturesAge   = $defender.AntivirusSignatureAge
}

$file = ".\health-$($cs.Name)-$(Get-Date -Format yyyyMMdd-HHmm).html"
$html = ($summary | ConvertTo-Html -Fragment -As List) +
        '<h3>Disks</h3>' + ($disks | ConvertTo-Html -Fragment) +
        '<h3>Automatic services not running</h3>' + ($stopped | ConvertTo-Html -Fragment)
ConvertTo-Html -Title "PC health $($cs.Name)" -Body $html | Out-File $file

$summary
$disks | Where-Object FreePct -lt 15 | ForEach-Object { Write-Warning "Low disk space on $($_.Drive): $($_.FreePct)% free" }
Write-Host "Report saved to $file"
