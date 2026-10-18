# Enterprise User Lifecycle Administration (AD)(RBAC)

**Ironbridge Bank & Trust | MRA Finding #1 | Simulated enterprise environment**

---


---

## Problem Statement

Ironbridge Bank & Trust is a 160 employee community bank. IT was outsourced to an MSP called VelocIT for five years, and after a regulatory examination the bank was issued a Matters Requiring Attention letter. Finding #1 was the directory.

What I inherited: every account in one flat container with no organizational units, no naming standard, passwords set to never expire, a terminated employee still enabled fourteen months after she left, and a former contractor still holding Domain Admin four years after he left the state.

The bank could not answer the examiners' question: who has access, and why.

When I first opened the directory, every account was piled into one container, making it impossible to tell which accounts were active, disabled, or server objects.

## Solution Overview

I reconciled Active Directory against the HR roster to establish who actually works at the bank, then classified every inherited account as keep, disable, leaver or service.

I designed and built an OU structure by department and branch, created role based security groups from a documented role catalog, and applied a naming standard to every object.

I migrated every surviving account with PowerShell, populating required attributes, granting access through role groups only, and clearing the non-expiring password flag across the bank. I then ran the full identity lifecycle against real tickets: a joiner, a mover, and two leavers.

---

## Key Work

**Remediated the examination finding.** Disabled the terminated account rather than deleting it, stripped its group memberships, reset the credential, and moved it to a Disabled Users OU with the termination documented on the object.

**Removed an unowned privileged account.** Processed it through a leaver script, dry run first, then live. Removed it from Domain Admins and preserved the account and logs as evidence.

**Answered the Domain Admin question.** Reviewed privileged membership recursively rather than by direct members, because a nested group grants admin rights to everyone inside it.

**Escalated rather than fixed.** Found a separation of duties conflict in the wire transfer workflow, where one person could both initiate and approve a transfer. Funds transfer access is owned by the wire system owner, so I documented it in an exception register and escalated it instead of changing it myself.

**Caught privilege creep in progress.** Processed a role change by adding the new role exactly as requested. The old role was still attached, so I removed it. Requests tell you what to add and never what to remove.

The step I would do differently next time is carefully run scripts on my PowerShell and make sure that changes were being made. It caused delays when trying to complete this project.

---

## Tools Used

Windows Server, Active Directory Domain Services, PowerShell, Group Policy Management, and VirtualBox.

---

## Repository Contents

- `Work/IB-STD-001-Directory-Standard.md` - the directory standard I authored
- `Work/scripts/` - PowerShell for recon, migration, cleanup and evidence
- `Runbook/` - the joiner, mover, leaver SOP this work followed
- `Evidence/` - before and after states, reports, exception register, audit log
- `Logs/` - dry run and live logs for every scripted change
- `screenshots/` - visual evidence at each phase

---

## What I Learned

**Disable, never delete.**
Every account has a hidden identifier called a SID (Security Identifier), and file permissions, mailbox rights and audit log entries all point at that SID rather than at the name. Delete the account and you will lose all evidence of user's previous key access and their job role with the company. 
<!-- FILL IN: finish the thought. What breaks? What happens if you recreate an account with the same name? -->

**Access belongs on groups, not people.**
A permission granted directly to a user works, but it never shows up in a group membership report, which means only that user has access to 


**A mover is two operations.**
The request asked me to give her loan processing access. It never mentioned removing her teller access, and I made sure to remove her teller access because that would cause a privileged creep and she would have more access to a group, she is no longer with. 
<!-- FILL IN: finish it. What happens if you only do the half you were asked for? What is that called? -->

**PowerShell script run**
When running a script on PowerShell always double check that changes are being made in Active Directory. I encounter one user not being disabled and one role was missing from AD groups. 
<!-- FILL IN: Add one of your own in the same shape, a bolded line and two or three sentences.
     Pick whatever genuinely got you: the thing that took longest, the mistake you made, or the moment something clicked. -->

---

*Built as part of the TotalThreat IT & IAM Career Accelerator. Ironbridge Bank & Trust is a simulated enterprise environment and not a real employer. The starting directory state and the scripts in `Tools/` were provided by the program. The investigation, directory standard, scripts, remediation and documentation are my own work.*
