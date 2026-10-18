
# RUN 1: dry run as-is. RUN 2: change line 3 to $false, save, run again.
$WhatIfPreference = $false
$Mode = if ($WhatIfPreference) { "DRYRUN" } else { "LIVE" }
$dn = (Get-ADDomain).DistinguishedName; $upn = (Get-ADDomain).DNSRoot; $ib = "OU=Ironbridge,$dn"
$HR  = Import-Csv C:\Ironbridge\HR\hr-roster.csv
$Cat = Import-Csv C:\Ironbridge\Runbook\role-catalog.csv
$Map = Import-Csv C:\Ironbridge\Work\account-mapping.csv
$log = "C:\Ironbridge\Logs\JML-1003-migration-$Mode-$(Get-Date -Format yyyyMMdd-HHmmss).log"
function W($m, $c = "Green") { $l = "$(Get-Date -Format s) | JML-1003 | $Mode | $m"; Write-Host $l -ForegroundColor $c; Add-Content -Path $log -Value $l -WhatIf:$false }

foreach ($r in ($Map | Where-Object Decision -eq 'KEEP')) {
  $h = $HR | Where-Object EmployeeID -eq $r.EmployeeID
  if (-not $h) { W "SKIP $($r.OldSam): EmployeeID '$($r.EmployeeID)' not in HR" Red; continue }
  $u = Get-ADUser -Filter "EmployeeID -eq '$($h.EmployeeID)'"
  if (-not $u) { $u = Get-ADUser -Filter "SamAccountName -eq '$($r.OldSam)'" }
  if (-not $u) { W "SKIP $($r.OldSam): no AD account found" Red; continue }
  $sam  = ($h.FirstName.Substring(0,1) + $h.LastName).ToLower()
  $full = "$($h.FirstName) $($h.LastName)"
  $role = ($Cat | Where-Object { ($_.Titles -split ';') -contains $h.Title }).Role
  $ou   = if ($h.Department -eq 'Retail Banking') { "OU=$($h.Branch),OU=Retail Banking,OU=Users,$ib" } else { "OU=$($h.Department),OU=Users,$ib" }
  Set-ADUser -Identity $u.ObjectGUID -SamAccountName $sam -UserPrincipalName "$sam@$upn" -GivenName $h.FirstName -Surname $h.LastName -DisplayName $full -EmployeeID $h.EmployeeID -Department $h.Department -Title $h.Title -Office $h.Branch -Company "Ironbridge Bank & Trust" -PasswordNeverExpires $false
  if ($role) { Add-ADGroupMember -Identity $role -Members $u -ErrorAction SilentlyContinue } else { W "WARNING $($full): title '$($h.Title)' not in role catalog" Red }
  if ($u.Name -ne $full) { Rename-ADObject -Identity $u.ObjectGUID -NewName $full }
  Move-ADObject -Identity $u.ObjectGUID -TargetPath $ou
  W "$($r.OldSam) to $sam | $($h.EmployeeID) | $($h.Title) | $role | password now expires | $ou"
}
foreach ($r in ($Map | Where-Object Decision -eq 'KEEP')) {
  $h = $HR | Where-Object EmployeeID -eq $r.EmployeeID
  if (-not $h -or -not $h.ManagerID) { continue }
  $u = Get-ADUser -Filter "EmployeeID -eq '$($h.EmployeeID)'"; $m = Get-ADUser -Filter "EmployeeID -eq '$($h.ManagerID)'"
  if ($u -and $m) { Set-ADUser -Identity $u -Manager $m; W "Manager: $($u.SamAccountName) reports to $($m.SamAccountName)" }
  elseif ($WhatIfPreference) { W "(dry run) manager for $($h.EmployeeID) is set in the live run" Yellow }
  else { W "WARNING: manager not set for $($h.EmployeeID)" Red }
}
foreach ($r in ($Map | Where-Object Decision -eq 'DISABLE')) {
  $u = Get-ADUser -Filter "SamAccountName -eq '$($r.OldSam)'"
  if (-not $u) { W "SKIP $($r.OldSam): not found" Red; continue }
  Disable-ADAccount -Identity $u
  Set-ADUser -Identity $u -Description "DISABLED | JML-1003 | No HR record or shared account | $(Get-Date -Format yyyy-MM-dd) | Do not delete before retention review"
  Move-ADObject -Identity $u -TargetPath "OU=Disabled Users,$ib"
  W "Disabled and preserved: $($r.OldSam)"
}
W "COMPLETE"