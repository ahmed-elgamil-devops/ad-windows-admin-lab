# Creates the company OU structure and one security group per department.
# Run on the domain controller as a Domain Admin.
Import-Module ActiveDirectory

$domainDN    = (Get-ADDomain).DistinguishedName
$departments = 'Finance', 'Sales', 'HR', 'IT'

if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Company'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name 'Company' -Path $domainDN
}
$companyOU = "OU=Company,$domainDN"

foreach ($ou in @('Users', 'Computers', 'Groups', 'Disabled')) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -SearchBase $companyOU -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ou -Path $companyOU
    }
}

foreach ($dept in $departments) {
    $usersOU = "OU=Users,$companyOU"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$dept'" -SearchBase $usersOU -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $dept -Path $usersOU
    }
    $group = "GRP-$dept"
    if (-not (Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $group -GroupScope Global -GroupCategory Security -Path "OU=Groups,$companyOU"
    }
}

Write-Host 'OU structure and department groups are ready.' -ForegroundColor Green
