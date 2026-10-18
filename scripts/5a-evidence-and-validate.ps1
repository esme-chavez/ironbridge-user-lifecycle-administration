# SCRIPT 5A | Save as C:\Ironbridge\Work\scripts\5a-evidence-and-validate.ps1 | SOP 8
$E = "C:\Ironbridge\Evidence"; $ib = "OU=Ironbridge,$((Get-ADDomain).DistinguishedName)"
Get-ADUser -SearchBase "OU=Users,$ib" -Filter 'Enabled -eq $true' -Properties EmployeeID,Department,Title,Office,Manager | Select-Object SamAccountName,Name,EmployeeID,Department,Title,Office,@{n='Manager';e={($_.Manager -split ',')[0] -replace '^CN='}} | Export-Csv "$E\AFTER-enabled-accounts.csv" -NoTypeInformation
Get-ADGroupMember "Domain Admins" -Recursive | Select-Object Name,SamAccountName | Export-Csv "$E\AFTER-domain-admins.csv" -NoTypeInformation
$rows = foreach ($g in Get-ADGroup -SearchBase "OU=Groups,$ib" -Filter "Name -like 'ROLE-*'") { Get-ADGroupMember $g | Select-Object @{n='Role';e={$g.Name}},Name,SamAccountName }
$rows | Export-Csv "$E\AFTER-role-membership.csv" -NoTypeInformation
Get-ADUser -Filter 'Enabled -eq $false' -Properties Description | Select-Object SamAccountName,Name,Description,DistinguishedName | Export-Csv "$E\AFTER-disabled-accounts.csv" -NoTypeInformation
$dl = Get-ChildItem "$env:USERPROFILE\Downloads\Ironbridge-ServiceDesk-AuditLog*.csv" -ErrorAction SilentlyContinue
if ($dl) { $dl | Move-Item -Destination $E -Force; Write-Host "ServiceDesk audit log filed in Evidence" -ForegroundColor Green }
else { Write-Host "No audit log in Downloads. Click Export audit log in the ServiceDesk, then run this again." -ForegroundColor Red }
Write-Host "Evidence pack written to $E" -ForegroundColor Green
& "C:\Ironbridge\Tools\Test-Ironbridge.ps1" *>&1 | Tee-Object "$E\VALIDATION-final.txt"