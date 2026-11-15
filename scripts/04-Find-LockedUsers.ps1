# Lists locked-out accounts and, for each one, the computer the bad
# password attempts came from (Security event 4740 on the domain controller).
Import-Module ActiveDirectory

$locked = Search-ADAccount -LockedOut | Select-Object SamAccountName, Name
if (-not $locked) { Write-Host 'No locked accounts.' -ForegroundColor Green; return }

$events = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4740 } -MaxEvents 200 -ErrorAction SilentlyContinue

foreach ($u in $locked) {
    $last = $events | Where-Object { $_.Properties[0].Value -eq $u.SamAccountName } | Select-Object -First 1
    [pscustomobject]@{
        User       = $u.SamAccountName
        LockedAt   = $last.TimeCreated
        SourcePC   = if ($last) { $last.Properties[1].Value } else { 'unknown' }
    }
}
