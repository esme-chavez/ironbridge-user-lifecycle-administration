# SCRIPT 4D | Save as C:\Ironbridge\Work\scripts\4d-retire-legacy.ps1 | JML-1003 | Run ONCE
$dom = Get-ADDomain; $ib = "OU=Ironbridge,$($dom.DistinguishedName)"; $E = "C:\Ironbridge\Evidence"
# 1. Service accounts (SOP 3.6 SERVICE)
$svc = @(
  @{Old="scanner";    New="svc-scanner"; Desc="SERVICE | Owner: IT | Purpose: branch copier scan-to-folder | EXCEPTION: holds Domain Admins, deferred to Project 6 review | JML-1003"},
  @{Old="svc_backup"; New="svc-backup";  Desc="SERVICE | Owner: IT | Purpose: VelocIT era backup job, confirm scope in Project 6 | JML-1003"}
)
foreach ($s in $svc) {
  $g = (Get-ADUser -Identity $s.Old).ObjectGUID
  Rename-ADObject -Identity $g -NewName $s.New
  Set-ADUser -Identity $g -SamAccountName $s.New -UserPrincipalName "$($s.New)@$($dom.DNSRoot)" -Description $s.Desc
  Move-ADObject -Identity $g -TargetPath "OU=Service Accounts,$ib"
  Write-Host "Service account: $($s.Old) is now $($s.New)" -ForegroundColor Green
}
# 2. Capture legacy membership as evidence, then retire the legacy groups
$legacy = "Tellers","Tellers2","Lending-Users","Loan-Files-Modify","Core-Banking-Users","VPN-Access","TEMP_AUDIT","Marcus Do Not Touch"
$rows = foreach ($lg in $legacy) {
  $mem = @(Get-ADGroupMember -Identity $lg)
  if ($mem.Count) { $mem | Select-Object @{n='LegacyGroup';e={$lg}},Name,SamAccountName,objectClass }
  else { [pscustomobject]@{ LegacyGroup = $lg; Name = '(no members)'; SamAccountName = ''; objectClass = '' } }
}
$rows | Export-Csv "$E\LEGACY-group-membership.csv" -NoTypeInformation
$rows | Format-Table -AutoSize
foreach ($lg in $legacy) { Remove-ADGroup -Identity $lg -Confirm:$false; Write-Host "Retired $lg" -ForegroundColor Green }
# 3. Exception register: findings IT documents and escalates, but does NOT fix alone (SOP 7.4)
$ex = @()
$ex += Get-ADGroupMember "Wire-Initiate" | ForEach-Object { [pscustomobject]@{ Finding = "Funds-transfer access"; Account = $_.SamAccountName; Detail = "Member of Wire-Initiate"; Owner = "Wire system owner"; Status = "Escalated to COO. Review in Project 6"; Ticket = "JML-1003" } }
$ex += Get-ADGroupMember "Wire-Approve"  | ForEach-Object { [pscustomobject]@{ Finding = "Funds-transfer access"; Account = $_.SamAccountName; Detail = "Member of Wire-Approve"; Owner = "Wire system owner"; Status = "Escalated to COO. Review in Project 6"; Ticket = "JML-1003" } }
$ex += [pscustomobject]@{ Finding = "Service account with Domain Admins"; Account = "svc-scanner"; Detail = "Copier account holds Domain Admins"; Owner = "IT and COO"; Status = "Documented exception. Review in Project 6"; Ticket = "JML-1003" }
$ex | Export-Csv "$E\EXCEPTIONS-register.csv" -NoTypeInformation
$ex | Format-Table -AutoSize
Write-Host "Exception register written. Read it carefully: who can both initiate AND approve a wire?" -ForegroundColor Yellow
# 4. AdminSDHolder cleanup for accounts that are no longer privileged
$keep = @('Administrator','krbtgt') + @((Get-ADGroupMember "Domain Admins" -Recursive).SamAccountName)
Get-ADUser -Filter 'adminCount -eq 1' | Where-Object { $_.SamAccountName -notin $keep } | ForEach-Object {
  Set-ADUser -Identity $_ -Clear adminCount
  $acl = Get-Acl -Path "AD:\$($_.DistinguishedName)"; $acl.SetAccessRuleProtection($false, $true); Set-Acl -Path "AD:\$($_.DistinguishedName)" -AclObject $acl
  Write-Host "AdminSDHolder cleanup: $($_.SamAccountName)" -ForegroundColor Green
}
Write-Host "Effective Domain Admins now:" -ForegroundColor Cyan
Get-ADGroupMember "Domain Admins" -Recursive | Select-Object SamAccountName