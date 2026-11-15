# Active Directory & Windows Admin Lab

A Windows Server 2022 domain (lab.local) built in VirtualBox, with PowerShell scripts for the daily help desk work: onboarding, password resets, lockout tracing, offboarding, PC health checks and asset inventory.

**Lab:** VM DC01 (Windows Server 2022, AD DS, DNS, DHCP) and VM PC01 (Windows 10/11 joined to the domain).

## Steps

1. Install Windows Server 2022 on a VM named `DC01`, set a static IP (for example `192.168.10.10/24`).
2. Add the **AD DS**, **DNS** and **DHCP** roles, promote to a new forest `lab.local`.
3. Create the OU structure and groups:
   ```powershell
   .\scripts\01-Create-OUs.ps1
   ```
4. Onboard users from CSV:
   ```powershell
   .\scripts\02-New-UsersFromCsv.ps1 -CsvPath .\users.csv
   ```
5. Daily help desk tasks:
   ```powershell
   .\scripts\03-Reset-UserPassword.ps1 -SamAccountName sara.ali
   .\scripts\04-Find-LockedUsers.ps1
   ```
6. Offboard a leaver (disable, remove groups, move to Disabled OU):
   ```powershell
   .\scripts\05-Disable-Leaver.ps1 -SamAccountName omar.hassan
   ```
7. Group Policies (create in Group Policy Management, document each one with a screenshot):
   - **Password policy:** 12 characters, lockout after 5 attempts for 15 minutes.
   - **Mapped drive:** `S:` to `\\DC01\Shared\<Department>` for each department group.
   - **Desktop wallpaper and lock screen** after 10 minutes idle.
   - **Block USB storage** for the Sales OU.
8. Join `PC01` to the domain, log in as a test user and confirm the GPOs apply with `gpresult /r`.

## What to capture

Screenshots of: OU tree, a user's group membership, each GPO's settings, `gpresult /r` on PC01,
and the output of each script.

## Endpoint scripts

- `endpoint-scripts/Get-PCHealthReport.ps1`: uptime, CPU, memory, disk space, pending reboot, Defender status and stopped services, saved as an HTML report.
- `endpoint-scripts/Get-AssetInventory.ps1`: model, serial number, CPU, RAM, disk and OS for one or many PCs, appended to an asset CSV.
