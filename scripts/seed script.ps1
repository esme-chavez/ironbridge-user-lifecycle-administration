# ============================================================
#  TOTALTHREAT | IT & IAM CAREER ACCELERATOR
#  SCRIPT 1B | Project 1 Workspace: Ironbridge Bank & Trust
#  Requires the Lab Setup handover. Creates NO accounts.
#  Paste into a NEW ISE tab and press F5. Do not save first. Runs ONCE.
# ============================================================
Import-Module ActiveDirectory
$ErrorActionPreference = "Stop"
$Root = "C:\Ironbridge"
if (Test-Path "$Root\seed.lock") { throw "STOP: the workspace was already created on $(Get-Content "$Root\seed.lock"). Nothing was changed. Continue with the checklist." }
foreach ($s in "dkowalczyk","mreynolds","kmarsh","mfoss") {
  if (-not (Get-ADUser -Filter "SamAccountName -eq '$s'")) { throw "STOP: the Lab Setup handover was not found ($s is missing). Go back to Lab Setup, run the handover script, then return here." }
}
$Dom  = Get-ADDomain
$Path = $Dom.UsersContainer
Write-Host "Preparing your first week at Ironbridge Bank & Trust..." -ForegroundColor Cyan

Write-Host "[1/6] Creating the Ironbridge workspace..." -ForegroundColor Yellow
foreach ($f in "HR","Runbook","Tools","Work","Work\scripts","Logs","Evidence") { New-Item -ItemType Directory -Path "$Root\$f" -Force | Out-Null }

Write-Host "[2/6] Writing HR records, role catalog, and mapping worksheet..." -ForegroundColor Yellow
$Term  = (Get-Date).AddMonths(-14).ToString("yyyy-MM-dd")
$Start = (Get-Date).AddDays(3).ToString("yyyy-MM-dd")
$HR = @'
EmployeeID,FirstName,LastName,Department,Title,Branch,ManagerID,Status,HireDate,TermDate
E1001,Ray,Whitfield,Executive,Chief Operating Officer,HQ,,Active,2006-06-01,
E1002,Rick,DeMarco,Retail Banking,Branch Manager,Maple Avenue,E1001,Active,2013-05-17,
E1003,Charlene,Boyd,Retail Banking,Head Teller,Elm Street,E1001,Active,2009-04-06,
E1004,Marlene,Foss,Retail Banking,Teller,Main Office,E1001,Active,2006-08-21,
E1005,Janet,Ruiz,Retail Banking,Teller,Maple Avenue,E1002,Active,2020-09-14,
E1006,Cheryl,Vance,Lending,Loan Administration Manager,HQ,E1001,Active,2014-02-03,
E1007,Doug,Pruitt,Lending,Mortgage Officer,HQ,E1006,Active,2019-01-09,
E1008,Priya,Raman,Lending,Loan Processor,HQ,E1006,Active,2022-02-13,
E1009,Kevin,Marsh,Wire Operations,Wire Operations Specialist,HQ,E1001,Active,2015-03-01,
E1010,Angela,Boone,Operations,Branch Operations Specialist,HQ,E1013,Active,2018-10-15,
E1011,Ted,Brunner,Operations,Branch Operations Specialist,HQ,E1013,Active,2016-06-20,
E1012,Sandra,Pike,Operations,Back Office Specialist,HQ,E1013,Active,2019-01-30,
E1013,Deb,Halloran,Operations,Operations Manager,HQ,E1001,Active,2012-09-10,
E1014,Tom,Eckert,Wealth Management,Wealth Advisor,HQ,E1001,Active,2017-04-24,
E1015,Bill,Tolliver,Operations,Facilities Coordinator,HQ,E1013,Active,2010-11-01,
E1016,Nadia,Brooks,Retail Banking,Teller,Elm Street,E1003,Pending Start,STARTDATE,
E0977,Denise,Kowalczyk,Lending,Loan Processor,HQ,E1006,Terminated,2018-06-04,TERMDATE
'@
$HR.Replace("STARTDATE",$Start).Replace("TERMDATE",$Term) | Set-Content "$Root\HR\hr-roster.csv" -Encoding UTF8
@'
Role,Titles,Description
ROLE-Executive,Chief Operating Officer,Executive leadership: management reporting and executive shared drive
ROLE-BranchManager,Branch Manager,Branch operations: teller overrides and branch reporting. No wire system access
ROLE-Teller,Teller;Head Teller,Teller platform and core banking (teller functions). No wire system access
ROLE-LoanProcessor,Loan Processor,Loan origination system (processing) and the loan file share
ROLE-LoanOfficer,Mortgage Officer,Loan origination system (origination) and credit reports
ROLE-LendingManager,Loan Administration Manager,Loan approvals and lending reports
ROLE-WireOperations,Wire Operations Specialist,Wire operations desk tools. Wire system rights are governed separately (SOP 7.4)
ROLE-Operations,Branch Operations Specialist;Back Office Specialist;Operations Manager,Back office and branch operations systems
ROLE-Facilities,Facilities Coordinator,Facilities and building systems only
ROLE-WealthAdvisor,Wealth Advisor,Wealth management platform and client files
'@ | Set-Content "$Root\Runbook\role-catalog.csv" -Encoding UTF8
$flat = Get-ADUser -Filter * -SearchBase $Path -SearchScope OneLevel | Where-Object { $_.SamAccountName -notin 'Administrator','Guest','krbtgt','DefaultAccount' } | Sort-Object SamAccountName
$MapText = "OldSam,EmployeeID,Decision`r`n" + (($flat | ForEach-Object { "$($_.SamAccountName),," }) -join "`r`n")
$MapText | Set-Content "$Root\Work\account-mapping.csv" -Encoding UTF8

Write-Host "[3/6] Writing the runbook..." -ForegroundColor Yellow
@'
IB-SOP-001 | USER ACCESS LIFECYCLE RUNBOOK (JOINER / MOVER / LEAVER)
Ironbridge Bank & Trust | Information Technology
Version 1.0 | Owner: IT Systems & Identity | Approved by: Ray Whitfield, COO
Remediates: Report of Examination IT-2025-0417, MRA #1
==========================================================================

1. PURPOSE
1.1 This runbook defines how every user account at Ironbridge is created, changed, and removed.
1.2 The goal: the bank can answer, at any moment, who has access, to what, and why.
1.3 No step is optional. If a step cannot be completed, stop and record why in the ticket.

2. AUTHORITY AND SOURCES OF TRUTH
2.1 HR is the authoritative source for employees. File: C:\Ironbridge\HR\hr-roster.csv
2.2 Service accounts require a named owner and a documented purpose.
2.3 No ticket, no change. Every account action is performed against a ServiceDesk ticket.
2.4 Required approvals:
    Joiner ..... HR record plus hiring manager
    Mover ...... receiving manager plus releasing manager or HR
    Leaver ..... HR termination record or COO authorization
    Privileged . COO
2.5 Urgency is not approval.

3. DIRECTORY BASELINE
3.1 Required OU structure:
    Ironbridge
      Users
        Executive | Lending | Wire Operations | Wealth Management | Operations | Compliance | IT
        Retail Banking
          Main Office | Elm Street | Maple Avenue | Riverside | Oak Hill
      Groups
      Computers
      Service Accounts
      Disabled Users
    Retail Banking staff are placed by branch. All other staff are placed by department.
    Every OU is protected from accidental deletion.
3.2 Naming:
    Users ............ first initial + last name, lowercase (Denise Kowalczyk = dkowalczyk)
    Collision ........ first two letters of first name + last name. Record it in the ticket.
    UPN .............. username@ironbridge.local
    Service accounts . svc- prefix. Never a human sounding name.
    Groups ........... ROLE- prefix. Role names come from the role catalog only.
    Computers ........ WKS-<SITE>-<NNN> (WKS-ELM-014)
3.3 Required attributes on every employee account:
    First name, Last name, Display name, Username, UPN, Employee ID, Title, Department,
    Office (branch or HQ), Company, Manager (all except Executive).
    Employee passwords must expire. "Password never expires" is for documented service accounts only.
3.4 Access model:
    Access is granted through ROLE- groups only. Never directly to a user.
    Every account holds exactly ONE role group. The only other groups permitted are the
    funds-transfer groups governed under Section 7.4.
    Roles are defined in C:\Ironbridge\Runbook\role-catalog.csv and mapped from job title.
    "Give them the same access as <coworker>" is never a valid request.
3.5 IT must author and maintain the Directory Standard, IB-STD-001 (Appendix A).
3.6 Legacy account disposition codes:
    KEEP ...... belongs to an active employee in HR. Migrate to standard.
    DISABLE ... matches no one, OR is a shared account. One identity, one account.
                Disable, stamp description, move to Disabled Users.
    LEAVER .... belongs to a terminated person or an orphan. Process under Section 6.
    SERVICE ... used by a device or application. Rename svc-, document owner, move to Service Accounts.

4. JOINER
4.1 Confirm the ticket and the approval.
4.2 Confirm the HR record: Employee ID, title, branch or department, manager.
4.3 Determine the role from the role catalog using the job title.
4.4 Generate the username (3.2). Check for a collision BEFORE creating anything.
4.5 Create the account directly in the correct OU (3.1). Populate every attribute in 3.3.
4.6 Temporary password, change required at next logon. Never send a password by email or chat.
4.7 Add the account to its ONE role group.
4.8 Verify attributes, OU, and group membership.
4.9 Record in the ticket: username, role, access granted, approver, date.

5. MOVER
5.1 Confirm approvals from the receiving manager and the releasing manager or HR.
5.2 Capture the BEFORE access to C:\Ironbridge\Evidence.
5.3 Add the new role group.
5.4 REMOVE the old role group. Mandatory. This is the most commonly missed step in access
    management, and it is exactly how privilege creep begins.
5.5 Update title, department, office, and manager.
5.6 Move the account to the OU for the new role.
5.7 Verify exactly one role group. Capture the AFTER state. Record both in the ticket.

6. LEAVER
6.1 Confirm the termination (HR) or the COO authorization.
6.2 Capture the BEFORE state to C:\Ironbridge\Evidence. Evidence first, always.
6.3 Disable the account.
6.4 Reset the password to a long random value. Clear "Password never expires".
6.5 Record, then remove, every group membership.
6.6 Stamp the description: LEAVER | <ticket> | Disabled <date> | Do not delete before retention review
6.7 Move the account to Disabled Users.
6.8 DO NOT DELETE. Deleting destroys the SID that every permission, file owner, and audit log
    entry points to. A recreated account gets a new SID and is a different identity.
    Deletion happens only after retention review, with documented approval.
6.9 Orphaned accounts (no HR record, no sponsor, no owner) are processed as leavers immediately.
    A privileged orphan is Critical priority.
6.10 One identity holds many accounts. List every other system the person may have used
     (email, core banking, loan origination, HR portal) as follow-up actions in the ticket.
6.11 The leaver tool, C:\Ironbridge\Tools\Invoke-IBLeaver.ps1, is always run with -WhatIf first.
     Review the dry run log, then run live. Both logs are retained as evidence.

7. PRIVILEGED AND HIGH RISK ACCESS
7.1 Review EFFECTIVE (recursive) membership of privileged groups, not only direct membership.
7.2 No nested groups inside Domain Admins.
7.3 Every privileged account has a named owner and a ticket. Any exception is written to the
    exception register (C:\Ironbridge\Evidence\EXCEPTIONS-register.csv) with an owner and a review date.
7.4 Funds-transfer groups (Wire-Initiate, Wire-Approve) are owned by the wire system owner.
    IT does NOT change them on its own. Record every member and every conflict in the exception
    register, then escalate to the COO. Separation of duties reviews happen with the system owner.

8. EVIDENCE AND AUDIT
8.1 Work notes are written DURING the work: what you did, the result, what it ruled out.
8.2 Logs: C:\Ironbridge\Logs        Evidence: C:\Ironbridge\Evidence
8.3 Export the ServiceDesk audit log at the end of every session.
8.4 Remediation is verified with C:\Ironbridge\Tools\Test-Ironbridge.ps1.
    Undocumented work is indistinguishable from work nobody did.

APPENDIX A | IB-STD-001 DIRECTORY STANDARD (IT TO AUTHOR)
Save as C:\Ironbridge\Work\IB-STD-001-Directory-Standard.md with these sections:
 1. Purpose and scope
 2. OU design, with the reason for each level (policy, delegation, or clarity)
 3. Naming conventions for users, service accounts, groups, computers, with examples
 4. Collision rule, with a worked example
 5. Required attributes, and why each one matters
 6. Access model: role groups only, one role per account, no direct permissions
 7. Role catalog summary, and who owns changes to it
 8. Account states (enabled, disabled, locked, expired) and why leavers are disabled, not deleted
 9. Privileged access rules and the exception register
10. Review cadence and document owner
'@ | Set-Content "$Root\Runbook\IB-SOP-001-JML-Runbook.txt" -Encoding UTF8

Write-Host "[4/6] Standing up the ServiceDesk..." -ForegroundColor Yellow
@'
<!DOCTYPE html><html><head><meta charset="utf-8"><title>Ironbridge ServiceDesk</title>
<style>
body{margin:0;font-family:Segoe UI,Arial,sans-serif;background:#eef0f2;color:#1d2733}
header{background:#1f3a5f;color:#fff;padding:10px 20px;display:flex;justify-content:space-between;align-items:center}
header h1{font-size:18px;margin:0}header small{opacity:.8}
.wrap{display:flex;height:calc(100vh - 58px)}
#list{width:360px;overflow:auto;background:#fff;border-right:1px solid #ccd}
.t{padding:10px 14px;border-bottom:1px solid #e3e6ea;cursor:pointer}
.t:hover,.t.on{background:#e6eef8}.t b{display:block;font-size:13px;margin-bottom:4px}.t span{font-size:12px;color:#556}
.pill{display:inline-block;font-size:11px;padding:2px 8px;border-radius:9px;margin-right:6px;color:#1d2733}
.New{background:#ffe2b8}.In{background:#cfe3ff}.Pending{background:#f7d0d0}.Resolved{background:#d3f0d3}.Closed{background:#ddd}.Rejected{background:#e8d0f0}
#detail{flex:1;overflow:auto;padding:20px 28px}
.card{background:#fff;border:1px solid #d5d9de;border-radius:6px;padding:16px;margin-bottom:14px}
table.f td{padding:3px 14px 3px 0;font-size:14px;vertical-align:top}table.f td:first-child{color:#667;width:120px}
pre{white-space:pre-wrap;font-family:inherit;margin:0;font-size:14px}
textarea{width:100%;min-height:80px;font:inherit;padding:8px;box-sizing:border-box}
button,select{font:inherit;padding:6px 12px;margin:6px 6px 0 0;cursor:pointer}
.note{border-left:3px solid #1f3a5f;padding:6px 10px;margin:8px 0;background:#f6f8fa;font-size:14px}.note i{color:#667;font-size:12px}
</style></head><body>
<header><div><h1>Ironbridge Bank &amp; Trust | IT ServiceDesk</h1><small>Identity Requests Queue (JML) | Internal use only</small></div>
<div><button onclick="exportCsv()">Export audit log (CSV)</button></div></header>
<div class="wrap"><div id="list"></div><div id="detail"><div class="card"><h2 style="margin-top:0">Welcome to the queue.</h2><p>Select a ticket on the left. Follow the Ticket Loop on every ticket. Export the audit log at the end of every session.</p></div></div></div>
<script>
const T=[
{id:"JML-1001",type:"Leaver (Remediation)",priority:"Critical",title:"Examiner finding: terminated employee still enabled",requester:"Ray Whitfield, COO (for the OFIS examination team)",approval:"APPROVED: Ray Whitfield, COO. HR termination record on file.",sop:"IB-SOP-001 Section 6",opened:"Mon 9:52 AM",body:"MRA #1 cites a former employee whose account remained enabled with a non-expiring password more than one year after separation.\n\nHR confirms the employee is Denise Kowalczyk (E0977), Loan Processor, Lending. Status: Terminated. The termination date is in the HR roster.\n\nRemediate per the leaver procedure. Capture her before state as evidence FIRST. Do NOT delete the account.\n\nBefore you close this, tell me which other bank systems Denise might still have a login to. The examiners will ask, and I do not want to guess.\n\nRay"},
{id:"JML-1002",type:"Leaver (Orphan)",priority:"Critical",title:"Unowned privileged account: mreynolds",requester:"IT internal review",approval:"APPROVED: Ray Whitfield, COO.",sop:"IB-SOP-001 Sections 6.9 and 6.11",opened:"Mon 9:58 AM",body:"During the directory review we found account mreynolds (Marcus Reynolds) holding Domain Admin rights. Its description reads DO NOT TOUCH.\n\nThere is no HR record for him. Marlene believes he did computer work for the bank about four years ago and moved to Arizona. A sticky note on the IT monitor reads 'Marcus - DO NOT TOUCH'. Nobody knows why.\n\nNo owner. No sponsor. No expiration. Process as an orphaned privileged account using the leaver tool. Dry run first."},
{id:"JML-1003",type:"Remediation",priority:"High",title:"Directory cleanup and the Domain Admin question",requester:"Ray Whitfield, COO",approval:"APPROVED: Ray Whitfield, COO.",sop:"IB-SOP-001 Sections 3 and 7",opened:"Mon 10:05 AM",body:"Three things.\n\nFirst, the examiners asked me a simple question I could not answer: who has domain administrator rights at this bank, and why? Not just the names on the group. Who can actually USE those rights.\n\nSecond, every account VelocIT left behind must be matched to a real person in HR, given complete attributes, placed in the correct OU, and granted access by role only. Anything that matches no one gets disabled and preserved. Shared logins get disabled too. Legacy groups get retired.\n\nThird, do NOT change anything that controls the wire system. If you find a problem there, write it down and bring it to me. The wire system owner and I will review it with the examiners.\n\nSource of truth: the HR roster.\nMapping worksheet: C:\\Ironbridge\\Work\\account-mapping.csv\n\nRay"},
{id:"JML-1004",type:"Joiner",priority:"High",title:"New hire: Nadia Brooks, Teller, Elm Street",requester:"Charlene Boyd, Head Teller, Elm Street",approval:"APPROVED: HR (offer accepted, E1016) and Charlene Boyd.",sop:"IB-SOP-001 Section 4",opened:"Mon 10:15 AM",body:"Hi! Nadia Brooks starts on my teller line this week.\n\nEmployee ID: E1016\nTitle: Teller\nBranch: Elm Street\nManager: Charlene Boyd (E1003)\n\nShe needs to be able to log in on day one. Standard teller access, nothing more. Please do not just copy somebody else's account.\n\nThanks,\nCharlene"},
{id:"JML-1005",type:"Mover",priority:"Medium",title:"Role change: Janet Ruiz, Teller to Loan Processor",requester:"Cheryl Vance, Loan Administration Manager",approval:"APPROVED: Cheryl Vance (receiving) and Rick DeMarco (releasing). HR notified.",sop:"IB-SOP-001 Section 5",opened:"Mon 11:30 AM",body:"Good news: Janet Ruiz is moving from the Maple Avenue teller line to Lending as a Loan Processor, effective today. Her new manager is me (E1006).\n\nCan you set her up with what she needs for loan processing?\n\nCheryl Vance, Loan Administration Manager"}
];
const KEY="ib-servicedesk-v1",STATES=["New","In Progress","Pending Approval","Resolved","Closed","Rejected"];
let S={};try{S=JSON.parse(localStorage.getItem(KEY))||{}}catch(e){S={}}
let cur=null;
function st(id){return S[id]||(S[id]={status:"New",notes:[],resolution:""})}
function save(){try{localStorage.setItem(KEY,JSON.stringify(S))}catch(e){alert("Could not save. Export your audit log now.")}}
function esc(s){return String(s).replace(/[&<>]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]))}
function stamp(){return new Date().toLocaleString()}
function renderList(){document.getElementById("list").innerHTML=T.map(t=>{const s=st(t.id).status;return `<div class="t ${t.id===cur?"on":""}" onclick="openT('${t.id}')"><b>${t.id} | ${esc(t.title)}</b><span class="pill ${s.split(" ")[0]}">${s}</span><span>${t.type} | ${t.priority}</span></div>`}).join("")}
function openT(id){cur=id;const t=T.find(x=>x.id===id),s=st(id);
document.getElementById("detail").innerHTML=`<div class="card"><h2 style="margin:0 0 8px">${t.id}: ${esc(t.title)}</h2><table class="f"><tr><td>Type</td><td>${t.type}</td></tr><tr><td>Priority</td><td>${t.priority}</td></tr><tr><td>Requester</td><td>${esc(t.requester)}</td></tr><tr><td>Approval</td><td><b>${esc(t.approval)}</b></td></tr><tr><td>Runbook</td><td>${t.sop}</td></tr><tr><td>Opened</td><td>${t.opened}</td></tr></table></div>
<div class="card"><h3 style="margin-top:0">Request</h3><pre>${esc(t.body)}</pre></div>
<div class="card"><h3 style="margin-top:0">Status</h3><select id="stsel">${STATES.map(o=>`<option ${o===s.status?"selected":""}>${o}</option>`).join("")}</select><button onclick="setStatus()">Update status</button></div>
<div class="card"><h3 style="margin-top:0">Work notes</h3>${s.notes.map(n=>`<div class="note"><i>${n.at}</i><br>${esc(n.text).replace(/\n/g,"<br>")}</div>`).join("")||"<p><i>No notes yet.</i></p>"}<textarea id="nt" placeholder="What you did. What happened. What it ruled out."></textarea><button onclick="addNote()">Add work note</button></div>
<div class="card"><h3 style="margin-top:0">Resolution</h3><textarea id="rs" placeholder="What changed, who approved it, which evidence files prove it, and the date.">${esc(s.resolution)}</textarea><button onclick="saveRes()">Save resolution</button></div>`;
renderList()}
function setStatus(){const s=st(cur),v=document.getElementById("stsel").value;if(v===s.status)return;s.notes.push({at:stamp(),text:"Status changed: "+s.status+" to "+v});s.status=v;save();openT(cur)}
function addNote(){const v=document.getElementById("nt").value.trim();if(!v)return;st(cur).notes.push({at:stamp(),text:v});save();openT(cur)}
function saveRes(){st(cur).resolution=document.getElementById("rs").value;save();alert("Resolution saved.")}
function exportCsv(){const q=v=>'"'+String(v).replace(/"/g,'""')+'"';const rows=[["Ticket","Title","Type","Status","Timestamp","Entry"]];T.forEach(t=>{const s=st(t.id);if(!s.notes.length)rows.push([t.id,t.title,t.type,s.status,"",""]);s.notes.forEach(n=>rows.push([t.id,t.title,t.type,s.status,n.at,n.text]));if(s.resolution)rows.push([t.id,t.title,t.type,s.status,"RESOLUTION",s.resolution])});const b=new Blob([rows.map(r=>r.map(q).join(",")).join("\r\n")],{type:"text/csv"});const a=document.createElement("a");a.href=URL.createObjectURL(b);a.download="Ironbridge-ServiceDesk-AuditLog.csv";a.click()}
renderList();
</script></body></html>
'@ | Set-Content "$Root\ServiceDesk.html" -Encoding UTF8

Write-Host "[5/6] Installing tools..." -ForegroundColor Yellow
@'
# Invoke-IBLeaver.ps1 | IB-SOP-001 Section 6 leaver tool
# ALWAYS run with -WhatIf first (SOP 6.11).
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [Parameter(Mandatory=$true)][string]$SamAccountName,
  [Parameter(Mandatory=$true)][string]$Ticket
)
Import-Module ActiveDirectory
$dn = (Get-ADDomain).DistinguishedName
$target = "OU=Disabled Users,OU=Ironbridge,$dn"
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$target'")) { throw "Disabled Users OU not found. Complete Phase 3 first." }
$Mode = if ($WhatIfPreference) { "DRYRUN" } else { "LIVE" }
$log = "C:\Ironbridge\Logs\LEAVER-$Mode-$SamAccountName-$(Get-Date -Format yyyyMMdd-HHmmss).log"
function W([string]$m) { $l = "$(Get-Date -Format s) | $Ticket | $Mode | $m"; Write-Host $l -ForegroundColor Cyan; Add-Content -Path $log -Value $l -WhatIf:$false }
$u = Get-ADUser -Identity $SamAccountName -Properties MemberOf,PasswordNeverExpires,PasswordLastSet,LastLogonDate,Description,adminCount
W "BEFORE | Enabled=$($u.Enabled) | PasswordNeverExpires=$($u.PasswordNeverExpires) | PasswordLastSet=$($u.PasswordLastSet) | LastLogon=$($u.LastLogonDate) | adminCount=$($u.adminCount)"
W "BEFORE | Groups=$((($u.MemberOf | ForEach-Object { ($_ -split ',')[0] -replace '^CN=','' }) -join '; '))"
if ($PSCmdlet.ShouldProcess($SamAccountName, "Disable account")) { Disable-ADAccount -Identity $u; W "Disabled account" }
if ($PSCmdlet.ShouldProcess($SamAccountName, "Reset password to random value and clear PasswordNeverExpires")) {
  $r = ConvertTo-SecureString ("Ib!" + [guid]::NewGuid().ToString() + "Zz9") -AsPlainText -Force
  Set-ADAccountPassword -Identity $u -Reset -NewPassword $r
  Set-ADUser -Identity $u -PasswordNeverExpires $false
  W "Password reset to a random value. PasswordNeverExpires cleared."
}
foreach ($g in $u.MemberOf) {
  $n = ($g -split ',')[0] -replace '^CN=',''
  if ($PSCmdlet.ShouldProcess($SamAccountName, "Remove from group $n")) { Remove-ADGroupMember -Identity $g -Members $u -Confirm:$false; W "Removed from $n" }
}
if ($u.adminCount -eq 1) {
  if ($PSCmdlet.ShouldProcess($SamAccountName, "Clear adminCount and re-enable permission inheritance")) {
    Set-ADUser -Identity $u -Clear adminCount
    $acl = Get-Acl -Path "AD:\$($u.DistinguishedName)"
    if ($acl.AreAccessRulesProtected) { $acl.SetAccessRuleProtection($false, $true); Set-Acl -Path "AD:\$($u.DistinguishedName)" -AclObject $acl }
    W "adminCount cleared and permission inheritance re-enabled"
  }
}
if ($PSCmdlet.ShouldProcess($SamAccountName, "Stamp description")) {
  Set-ADUser -Identity $u -Description "LEAVER | $Ticket | Disabled $(Get-Date -Format yyyy-MM-dd) | Do not delete before retention review"
  W "Description stamped"
}
if ($PSCmdlet.ShouldProcess($SamAccountName, "Move to Disabled Users")) { Move-ADObject -Identity $u.DistinguishedName -TargetPath $target; W "Moved to Disabled Users" }
W "COMPLETE | Account preserved, not deleted | Log: $log"
'@ | Set-Content "$Root\Tools\Invoke-IBLeaver.ps1" -Encoding UTF8

@'
# Test-Ironbridge.ps1 | TotalThreat Project 1 remediation validator
Import-Module ActiveDirectory
$dom = Get-ADDomain; $dn = $dom.DistinguishedName; $upn = $dom.DNSRoot
$ib = "OU=Ironbridge,$dn"; $usr = "OU=Users,$ib"; $R = "C:\Ironbridge"
$script:P = 0; $script:F = 0
function Check($Name, $Ok, $Hint) {
  if ([bool]$Ok) { Write-Host "PASS  $Name" -ForegroundColor Green; $script:P++ }
  else { Write-Host "FAIL  $Name" -ForegroundColor Red; if ($Hint) { Write-Host "      $Hint" -ForegroundColor DarkGray }; $script:F++ }
}
function Q([scriptblock]$S) { try { & $S } catch { } }
function Grp($u) { @($u.MemberOf | ForEach-Object { ($_ -split ',')[0] -replace '^CN=','' }) }
function Sec($t) { Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }
Write-Host ""; Write-Host "IRONBRIDGE BANK & TRUST | MRA #1 REMEDIATION CHECK | $(Get-Date)" -ForegroundColor Cyan

Sec "FOUNDATION"
$rbf = @(Q { Get-ADOptionalFeature -Filter "Name -like 'Recycle Bin*'" -ErrorAction Stop })
Check "AD Recycle Bin is enabled" ($rbf.Count -gt 0 -and @($rbf[0].EnabledScopes).Count -gt 0) "Phase 1, Script 1A"

Sec "STRUCTURE"
$need = @("OU=Users,$ib","OU=Groups,$ib","OU=Computers,$ib","OU=Service Accounts,$ib","OU=Disabled Users,$ib")
$need += "Executive","Lending","Wire Operations","Wealth Management","Operations","Compliance","IT","Retail Banking" | ForEach-Object { "OU=$_,$usr" }
$need += "Main Office","Elm Street","Maple Avenue","Riverside","Oak Hill" | ForEach-Object { "OU=$_,OU=Retail Banking,$usr" }
$missOU = @($need | Where-Object { $d = $_; -not (Q { Get-ADOrganizationalUnit -Identity $d -ErrorAction Stop }) })
Check "OU structure matches SOP 3.1 ($($need.Count) OUs)" ($missOU.Count -eq 0) ("Phase 3. Missing: " + (($missOU | ForEach-Object { ($_ -split ',OU=Ironbridge')[0] }) -join ' | '))
$unprot = @(Q { Get-ADOrganizationalUnit -SearchBase $ib -Filter * -Properties ProtectedFromAccidentalDeletion -ErrorAction Stop } | Where-Object { -not $_.ProtectedFromAccidentalDeletion })
Check "Every Ironbridge OU is protected from accidental deletion" ($unprot.Count -eq 0) ("Phase 3. Unprotected: " + ($unprot.Name -join ', '))
$cat = Import-Csv "$R\Runbook\role-catalog.csv"
$badG = @(foreach ($c in $cat) { $n = $c.Role; $g = Q { Get-ADGroup -Identity $n -Properties Description -ErrorAction Stop }; if (-not $g -or "$($g.GroupCategory)" -ne "Security" -or -not $g.Description -or $g.DistinguishedName -notlike "*,OU=Groups,$ib") { $n } })
Check "All $($cat.Count) catalog roles exist as described Security groups in Groups" ($badG.Count -eq 0) ("Phase 3. Fix: " + ($badG -join ', '))

Sec "LEAVERS (JML-1001 and JML-1002)"
$d = Q { Get-ADUser -Identity dkowalczyk -Properties MemberOf,Description,PasswordNeverExpires -ErrorAction Stop }
if ($d) {
  Check "Denise: account preserved, not deleted" $true ""
  Check "Denise: disabled" (-not $d.Enabled) "SOP 6.3"
  Check "Denise: password never expires cleared" (-not $d.PasswordNeverExpires) "SOP 6.4"
  Check "Denise: every group membership removed" (@($d.MemberOf).Count -eq 0) "SOP 6.5"
  Check "Denise: description references JML-1001" ($d.Description -like "*JML-1001*") "SOP 6.6"
  Check "Denise: located in Disabled Users" ($d.DistinguishedName -like "*,OU=Disabled Users,$ib") "SOP 6.7"
} else { Check "Denise: account preserved, not deleted" $false "The account is gone. Restore it from the Recycle Bin (SOP 6.8)" }
$m = Q { Get-ADUser -Identity mreynolds -Properties MemberOf,Description -ErrorAction Stop }
Check "Marcus: disabled, stripped, stamped, in Disabled Users" ($m -and (-not $m.Enabled) -and @($m.MemberOf).Count -eq 0 -and $m.Description -like "*JML-1002*" -and $m.DistinguishedName -like "*,OU=Disabled Users,$ib") "Phase 4, Script 4B"
$dry  = Get-ChildItem "$R\Logs\LEAVER-DRYRUN-mreynolds*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -First 1
$live = Get-ChildItem "$R\Logs\LEAVER-LIVE-mreynolds*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -First 1
Check "Marcus: dry run logged BEFORE the live run" ($dry -and $live -and $dry.LastWriteTime -lt $live.LastWriteTime) "SOP 6.11"

Sec "CLEANUP (JML-1003)"
$left = @(Q { Get-ADUser -SearchBase $dom.UsersContainer -SearchScope OneLevel -Filter 'Enabled -eq $true' -ErrorAction Stop } | Where-Object { $_.SamAccountName -ne 'Administrator' })
Check "Default Users container holds no active accounts" ($left.Count -eq 0) ("Scripts 4C and 4D. Still there: " + ($left.SamAccountName -join ', '))
$junk = @(foreach ($j in "teller_new","teller_new2","TEMP","TEMP_DO_NOT_USE","asdf","test","vpn_user") { $a = Q { Get-ADUser -Identity $j -ErrorAction Stop }; if (-not $a) { "$j (DELETED)" } elseif ($a.Enabled -or $a.DistinguishedName -notlike "*,OU=Disabled Users,$ib") { $j } })
Check "All 7 junk and shared accounts disabled, preserved, in Disabled Users" ($junk.Count -eq 0) ("Script 4C. Fix: " + ($junk -join ', '))
$leg = @(foreach ($g in "Tellers","Tellers2","Lending-Users","Loan-Files-Modify","Core-Banking-Users","VPN-Access","TEMP_AUDIT","Marcus Do Not Touch") { if (Q { Get-ADGroup -Identity $g -ErrorAction Stop }) { $g } })
Check "Legacy groups retired (8)" ($leg.Count -eq 0) ("Script 4D. Still present: " + ($leg -join ', '))
$km = Q { Get-ADUser -Identity kmarsh -Properties MemberOf -ErrorAction Stop }
$ab = Q { Get-ADUser -Identity aboone -Properties MemberOf -ErrorAction Stop }
$wireOk = (Q { Get-ADGroup -Identity "Wire-Initiate" -ErrorAction Stop }) -and (Q { Get-ADGroup -Identity "Wire-Approve" -ErrorAction Stop }) -and $km -and ((Grp $km) -contains 'Wire-Initiate') -and ((Grp $km) -contains 'Wire-Approve') -and $ab -and ((Grp $ab) -contains 'Wire-Initiate')
Check "Funds-transfer groups left untouched for the wire system owner" $wireOk "SOP 7.4. IT documents wire findings, it does not change them. Restore anything removed."
Check "Exception register written" (Test-Path "$R\Evidence\EXCEPTIONS-register.csv") "Script 4D"
$svc = @(Q { Get-ADUser -SearchBase "OU=Service Accounts,$ib" -Filter "SamAccountName -like 'svc-*'" -Properties Description -ErrorAction Stop } | Where-Object { $_.Description -like "*Owner*" })
Check "Both service accounts renamed svc-, owners documented, in Service Accounts" ($svc.Count -ge 2) "Script 4D"
$daNest = @(Q { Get-ADGroupMember -Identity "Domain Admins" -ErrorAction Stop } | Where-Object { $_.objectClass -eq 'group' })
Check "Domain Admins contains no nested groups" ($daNest.Count -eq 0) ("SOP 7.2. Nested: " + ($daNest.Name -join ', '))
$da = @(Q { Get-ADGroupMember -Identity "Domain Admins" -Recursive -ErrorAction Stop } | Where-Object { $_.SamAccountName -notin 'Administrator','svc-scanner' })
Check "Effective Domain Admins: Administrator plus the documented svc-scanner exception only" ($da.Count -eq 0) ("SOP 7.1. Unexpected admins: " + ($da.SamAccountName -join ', '))

Sec "IDENTITY STANDARD"
$emp = @(Q { Get-ADUser -SearchBase $usr -Filter 'Enabled -eq $true' -Properties EmployeeID,Department,Title,Office,Manager,MemberOf,GivenName,Surname -ErrorAction Stop })
$want = @(Import-Csv "$R\HR\hr-roster.csv" | Where-Object { $_.Status -ne 'Terminated' } | ForEach-Object { $_.EmployeeID })
$missE = @($want | Where-Object { $emp.EmployeeID -notcontains $_ })
Check "Every active HR employee ($($want.Count)) has an enabled account" ($missE.Count -eq 0) ("Missing EmployeeID: " + ($missE -join ', '))
$dupE = @($emp | Group-Object EmployeeID | Where-Object { $_.Count -gt 1 })
Check "No EmployeeID is used twice" ($dupE.Count -eq 0) ("Duplicated: " + ($dupE.Name -join ', '))
$attr = @($emp | Where-Object { -not $_.EmployeeID -or -not $_.Department -or -not $_.Title -or -not $_.Office -or -not $_.GivenName -or -not $_.Surname -or (-not $_.Manager -and $_.Department -ne 'Executive') })
Check "Every employee has all SOP 3.3 attributes" ($attr.Count -eq 0) ("Incomplete: " + ($attr.SamAccountName -join ', '))
$nm = @($emp | Where-Object { $u = $_; if (-not $u.GivenName -or -not $u.Surname) { $true } else { $a = ($u.GivenName.Substring(0,1) + $u.Surname).ToLower(); $b = ($u.GivenName.Substring(0,2) + $u.Surname).ToLower(); ($u.SamAccountName -cne $a -and $u.SamAccountName -cne $b) -or ($u.UserPrincipalName -ne "$($u.SamAccountName)@$upn") } })
Check "Every username and UPN follow SOP 3.2" ($nm.Count -eq 0) ("Nonstandard: " + ($nm.SamAccountName -join ', '))
$ouBad = @($emp | Where-Object { $u = $_; $exp = if ($u.Department -eq 'Retail Banking') { "OU=$($u.Office),OU=Retail Banking,$usr" } else { "OU=$($u.Department),$usr" }; $u.DistinguishedName -notlike "*,$exp" })
Check "Every employee is in the OU for their branch or department" ($ouBad.Count -eq 0) ("Misplaced: " + ($ouBad.SamAccountName -join ', '))
$roleBad = @($emp | Where-Object { $g = Grp $_; (@($g | Where-Object { $_ -like 'ROLE-*' }).Count -ne 1) -or (@($g | Where-Object { $_ -notlike 'ROLE-*' -and $_ -notin 'Wire-Initiate','Wire-Approve' }).Count -gt 0) })
Check "Every account holds exactly one role group (plus governed wire groups only)" ($roleBad.Count -eq 0) ("SOP 3.4. Fix: " + ($roleBad.SamAccountName -join ', '))
$match = @($emp | Where-Object { $u = $_; $t = $u.Title; $r = ($cat | Where-Object { ($_.Titles -split ';') -contains $t }).Role; (Grp $u) -notcontains $r })
Check "Every employee's role matches their title in the role catalog" ($match.Count -eq 0) ("Mismatch: " + ($match.SamAccountName -join ', '))
$pne = @(Q { Get-ADUser -Filter 'Enabled -eq $true -and PasswordNeverExpires -eq $true' -ErrorAction Stop } | Where-Object { $_.SamAccountName -ne 'Administrator' -and $_.DistinguishedName -notlike "*,OU=Service Accounts,$ib" })
Check "No enabled human account has a non expiring password" ($pne.Count -eq 0) ("Script 4C. Fix: " + ($pne.SamAccountName -join ', '))

Sec "MOVER (JML-1005)"
$t = @($emp | Where-Object { $_.EmployeeID -eq 'E1005' })
if ($t.Count) {
  $tg = Grp $t[0]
  Check "Janet: added to ROLE-LoanProcessor" ($tg -contains 'ROLE-LoanProcessor') "SOP 5.3"
  Check "Janet: REMOVED from ROLE-Teller" ($tg -notcontains 'ROLE-Teller') "SOP 5.4. Adding without removing is privilege creep."
  Check "Janet: title, department, and OU updated" ($t[0].Title -eq 'Loan Processor' -and $t[0].Department -eq 'Lending' -and $t[0].DistinguishedName -like "*,OU=Lending,$usr") "SOP 5.5 and 5.6"
} else { Check "Janet found by EmployeeID E1005" $false "Script 4C sets EmployeeID" }

Sec "DOCUMENTATION AND EVIDENCE"
$std = Get-Item "$R\Work\IB-STD-001-Directory-Standard.md" -ErrorAction SilentlyContinue
Check "IB-STD-001 directory standard written (2000+ characters)" ($std -and $std.Length -gt 2000) "Phase 2, Script 2D"
$files = "Evidence\BEFORE-accounts.csv","Evidence\RECON-ad-vs-hr.csv","Evidence\JML-1003-domain-admins-BEFORE.txt","Evidence\JML-1001-dkowalczyk-BEFORE.txt","Evidence\JML-1001-dkowalczyk-AFTER.txt","Evidence\LEGACY-group-membership.csv","Evidence\EXCEPTIONS-register.csv","Evidence\JML-1005-jruiz-BEFORE.txt","Evidence\JML-1005-jruiz-AFTER.txt","Evidence\AFTER-enabled-accounts.csv","Evidence\AFTER-domain-admins.csv","Evidence\AFTER-role-membership.csv","Evidence\AFTER-disabled-accounts.csv","Logs\JML-1003-migration-DRYRUN-*","Logs\JML-1003-migration-LIVE-*"
$mf = @($files | Where-Object { -not (Test-Path "$R\$_") })
Check "All evidence files and logs present ($($files.Count))" ($mf.Count -eq 0) ("Missing: " + ($mf -join ' | '))
$audit = Get-ChildItem "$R\Evidence\Ironbridge-ServiceDesk-AuditLog*.csv" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
if ($audit) {
  $al = Import-Csv $audit.FullName
  foreach ($id in "JML-1001","JML-1002","JML-1003","JML-1004","JML-1005") {
    $rows = @($al | Where-Object { $_.Ticket -eq $id })
    $stat = if ($rows.Count) { $rows[0].Status } else { "MISSING" }
    $notes = @($rows | Where-Object { $_.Timestamp -and $_.Timestamp -ne 'RESOLUTION' -and $_.Entry -notlike 'Status changed*' }).Count
    $res = @($rows | Where-Object { $_.Timestamp -eq 'RESOLUTION' }).Count
    Check "$id is Closed with work notes and a resolution" ($stat -eq 'Closed' -and $notes -ge 1 -and $res -ge 1) "Status: $stat | Work notes: $notes | Resolution: $(if ($res) { 'yes' } else { 'missing' })"
  }
} else { Check "ServiceDesk audit log exported into Evidence" $false "Export the audit log, then run Script 5A" }

Write-Host ""
Write-Host "RESULT: $($script:P) PASS | $($script:F) FAIL" -ForegroundColor Cyan
if ($script:F -eq 0) { Write-Host "MRA #1 REMEDIATION VERIFIED. Ship it." -ForegroundColor Green }
else { Write-Host "Keep going. Every FAIL names the phase, script, or runbook section to revisit." -ForegroundColor Yellow }
'@ | Set-Content "$Root\Tools\Test-Ironbridge.ps1" -Encoding UTF8

Write-Host "[6/6] Creating desktop shortcuts..." -ForegroundColor Yellow
$Desk = [Environment]::GetFolderPath("Desktop")
$ws = New-Object -ComObject WScript.Shell
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$sc = $ws.CreateShortcut("$Desk\Ironbridge ServiceDesk.lnk")
if (Test-Path $edge) { $sc.TargetPath = $edge; $sc.Arguments = "file:///C:/Ironbridge/ServiceDesk.html" }
else { $sc.TargetPath = "$Root\ServiceDesk.html"; Write-Host "  WARNING: Microsoft Edge not found. Open file:///C:/Ironbridge/ServiceDesk.html in any modern browser." -ForegroundColor Red }
$sc.Save()
$sc = $ws.CreateShortcut("$Desk\IB-SOP-001 Runbook.lnk"); $sc.TargetPath = "notepad.exe"; $sc.Arguments = "$Root\Runbook\IB-SOP-001-JML-Runbook.txt"; $sc.Save()
$sc = $ws.CreateShortcut("$Desk\Ironbridge Files.lnk"); $sc.TargetPath = $Root; $sc.Save()
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
(Get-Date -Format "yyyy-MM-dd HH:mm") | Set-Content "$Root\seed.lock"
$ErrorActionPreference = "Continue"
Write-Host ""
Write-Host "WORKSPACE READY. $($flat.Count) inherited accounts are waiting in your mapping worksheet." -ForegroundColor Cyan
Write-Host "Three shortcuts are on your desktop: ServiceDesk, Runbook, Ironbridge Files." -ForegroundColor Cyan
Write-Host "Welcome to Ironbridge. The queue is waiting." -ForegroundColor Cyan
