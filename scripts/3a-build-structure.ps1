# SCRIPT 3A | Save as C:\Ironbridge\Work\scripts\3a-build-structure.ps1 | SOP 3.1 and 3.4
$dn = (Get-ADDomain).DistinguishedName
$ib = "OU=Ironbridge,$dn"
function New-IBOU($Name, $Path) {
  if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq 'OU=$Name,$Path'") { Write-Host "Exists:  OU=$Name" -ForegroundColor DarkYellow }
  else { New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true; Write-Host "Created: OU=$Name,$Path" -ForegroundColor Green }
}
New-IBOU "Ironbridge" $dn
foreach ($o in "Users","Groups","Computers","Service Accounts","Disabled Users") { New-IBOU $o $ib }
foreach ($o in "Executive","Lending","Wire Operations","Wealth Management","Operations","Compliance","IT","Retail Banking") { New-IBOU $o "OU=Users,$ib" }
foreach ($o in "Main Office","Elm Street","Maple Avenue","Riverside","Oak Hill") { New-IBOU $o "OU=Retail Banking,OU=Users,$ib" }
$gp = "OU=Groups,$ib"
Import-Csv C:\Ironbridge\Runbook\role-catalog.csv | ForEach-Object {
  if (Get-ADGroup -Filter "Name -eq '$($_.Role)'") { Set-ADGroup -Identity $_.Role -Description $_.Description; Write-Host "Exists (description refreshed): $($_.Role)" -ForegroundColor DarkYellow }
  else { New-ADGroup -Name $_.Role -SamAccountName $_.Role -GroupCategory Security -GroupScope Global -Path $gp -Description $_.Description; Write-Host "Created: $($_.Role)" -ForegroundColor Green }
}