# Onboards new employees from a CSV file: creates the account in the right
# department OU, adds it to the department group, and forces a password change.
param(
    [Parameter(Mandatory)] [string] $CsvPath
)
Import-Module ActiveDirectory

$domain    = (Get-ADDomain)
$companyOU = "OU=Company,$($domain.DistinguishedName)"
$log       = @()

foreach ($row in Import-Csv $CsvPath) {
    $sam = ("$($row.FirstName).$($row.LastName)").ToLower()
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        $log += [pscustomobject]@{ User = $sam; Result = 'Skipped (already exists)' }
        continue
    }

    $tempPassword = ConvertTo-SecureString ("Welcome@" + (Get-Random -Minimum 1000 -Maximum 9999)) -AsPlainText -Force
    New-ADUser -Name "$($row.FirstName) $($row.LastName)" `
        -GivenName $row.FirstName -Surname $row.LastName `
        -SamAccountName $sam -UserPrincipalName "$sam@$($domain.DNSRoot)" `
        -Department $row.Department -Title $row.Title `
        -Path "OU=$($row.Department),OU=Users,$companyOU" `
        -AccountPassword $tempPassword -ChangePasswordAtLogon $true -Enabled $true

    Add-ADGroupMember -Identity "GRP-$($row.Department)" -Members $sam
    $log += [pscustomobject]@{ User = $sam; Result = "Created in $($row.Department)" }
}

$log | Format-Table -AutoSize
$log | Export-Csv -Path ".\onboarding-log-$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
