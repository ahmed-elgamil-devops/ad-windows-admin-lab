# Offboards a leaver: disables the account, records its groups,
# removes group memberships and moves it to the Disabled OU.
param(
    [Parameter(Mandatory)] [string] $SamAccountName
)
Import-Module ActiveDirectory

$domainDN = (Get-ADDomain).DistinguishedName
$user     = Get-ADUser -Identity $SamAccountName -Properties MemberOf

$groups = $user.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }
"$(Get-Date -Format s),$SamAccountName,$($groups -join ';')" | Add-Content '.\offboarding-log.csv'

Disable-ADAccount -Identity $SamAccountName
foreach ($g in $user.MemberOf) { Remove-ADGroupMember -Identity $g -Members $SamAccountName -Confirm:$false }
Set-ADUser -Identity $SamAccountName -Description "Disabled on $(Get-Date -Format yyyy-MM-dd)"
Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=Disabled,OU=Company,$domainDN"

Write-Host "$SamAccountName disabled and moved to the Disabled OU. Groups saved in offboarding-log.csv." -ForegroundColor Green
