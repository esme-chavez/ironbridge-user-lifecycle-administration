# SCRIPT 2A | Save as C:\Ironbridge\Work\scripts\2a-investigate.ps1 | JML-1003
$E = "C:\Ironbridge\Evidence"

# 1. Before state of every account
Get-ADUser -Filter * -Properties PasswordNeverExpires,Department,Title,Description,MemberOf | Select-Object SamAccountName,Name,Enabled,PasswordNeverExpires,Department,Title,Description,@{n='Groups';e={($_.MemberOf | ForEach-Object { ($_ -split ',')[0] -replace '^CN=' }) -join '; '}} | Export-Csv "$E\BEFORE-accounts.csv" -NoTypeInformation

# 2. Reconcile AD against HR, the source of truth
$HR = Import-Csv C:\Ironbridge\HR\hr-roster.csv
$recon = Get-ADUser -SearchBase (Get-ADDomain).UsersContainer -Filter * -Properties PasswordNeverExpires |
  Where-Object { $_.SamAccountName -notin 'Administrator','Guest','krbtgt','DefaultAccount' } |
  Select-Object SamAccountName, Name, Enabled, PasswordNeverExpires,
    @{n='HRStatus';e={ $n = $_.Name; $h = $HR | Where-Object { "$($_.FirstName) $($_.LastName)" -eq $n }; if ($h) { "$($h.Status) | $($h.EmployeeID) | $($h.Title)" } else { 'NO HR RECORD' } }} |
  Sort-Object HRStatus
$recon | Format-Table -AutoSize
$recon | Export-Csv "$E\RECON-ad-vs-hr.csv" -NoTypeInformation

# 3. Who is actually a Domain Admin?
$f = "$E\JML-1003-domain-admins-BEFORE.txt"
"DIRECT MEMBERS" | Out-File $f
Get-ADGroupMember "Domain Admins" | Select-Object Name,SamAccountName,objectClass | Format-Table -AutoSize | Out-File $f -Append
"EFFECTIVE MEMBERS (RECURSIVE)" | Out-File $f -Append
Get-ADGroupMember "Domain Admins" -Recursive | Select-Object Name,SamAccountName | Format-Table -AutoSize | Out-File $f -Append
notepad $f
