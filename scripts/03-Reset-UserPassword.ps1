# Help desk password reset: unlocks the account, sets a temporary password
# and forces the user to choose a new one at next logon.
# Always verify the caller's identity before running this.
param(
    [Parameter(Mandatory)] [string] $SamAccountName
)
Import-Module ActiveDirectory

$user = Get-ADUser -Identity $SamAccountName -Properties LockedOut, Enabled
if (-not $user.Enabled) {
    Write-Warning "$SamAccountName is disabled. Check with HR before enabling it."
    return
}

$temp = ConvertTo-SecureString ("Reset@" + (Get-Random -Minimum 1000 -Maximum 9999)) -AsPlainText -Force
Set-ADAccountPassword -Identity $SamAccountName -NewPassword $temp -Reset
Set-ADUser -Identity $SamAccountName -ChangePasswordAtLogon $true
if ($user.LockedOut) { Unlock-ADAccount -Identity $SamAccountName }

Write-Host "Password reset for $SamAccountName. Give the temporary password to the user by phone, not email." -ForegroundColor Green
