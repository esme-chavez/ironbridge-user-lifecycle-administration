# SCRIPT 2C | Save as C:\Ironbridge\Work\scripts\2c-check-mapping.ps1
$HR  = Import-Csv C:\Ironbridge\HR\hr-roster.csv
$Map = Import-Csv C:\Ironbridge\Work\account-mapping.csv
$view = foreach ($r in $Map) {
  $h = $HR | Where-Object { $_.EmployeeID -eq $r.EmployeeID }
  [pscustomobject]@{ OldSam = $r.OldSam; Decision = $r.Decision; EmployeeID = $r.EmployeeID; HRRecord = if ($h) { "$($h.FirstName) $($h.LastName) | $($h.Title) | $($h.Status)" } else { "" } }
}
$view | Format-Table -AutoSize
$termIDs = ($HR | Where-Object Status -eq 'Terminated').EmployeeID
$bad  = @($Map | Where-Object { $_.Decision -notin 'KEEP','DISABLE','LEAVER','SERVICE' })
$noid = @($Map | Where-Object { $_.Decision -eq 'KEEP' -and ($HR.EmployeeID -notcontains $_.EmployeeID) })
$term = @($Map | Where-Object { $_.Decision -eq 'KEEP' -and ($termIDs -contains $_.EmployeeID) })
$dup  = @($Map | Where-Object Decision -eq 'KEEP' | Group-Object EmployeeID | Where-Object Count -gt 1)
if ($bad.Count)  { Write-Host "Missing or invalid Decision: $($bad.OldSam -join ', ')" -ForegroundColor Red }
if ($noid.Count) { Write-Host "KEEP rows with no matching HR EmployeeID: $($noid.OldSam -join ', ')" -ForegroundColor Red }
if ($term.Count) { Write-Host "KEEP rows pointing at a TERMINATED employee: $($term.OldSam -join ', ')" -ForegroundColor Red }
if ($dup.Count)  { Write-Host "Same EmployeeID used twice: $($dup.Name -join ', ')" -ForegroundColor Red }
Write-Host ("Your counts: " + (($Map | Group-Object Decision | ForEach-Object { "$($_.Name) $($_.Count)" }) -join ' | ')) -ForegroundColor Cyan
if (-not ($bad.Count + $noid.Count + $term.Count + $dup.Count)) { Write-Host "Mapping is valid. Correct counts are: KEEP 15 | DISABLE 7 | LEAVER 2 | SERVICE 2" -ForegroundColor Green }