IB-STD-001 — Directory Standard
Ironbridge Bank & Trust  
Domain: ironbridge.local  
Owner: IT & Identity Specialist

1. Purpose and Scope
This standard defines how Ironbridge Bank & Trust structures and manages its directory.
Its purpose is to ensure the bank can answer who has access and why, remediating MRA #1.
It applies to all users, service accounts, computers, and groups in ironbridge.local.
It improves consistency, supports audits, and reduces identity risk.

2. OU Design
Every OU exists for a clear reason: policy, delegation, or clarity.

Top-level OUs
Users — policy. Holds all human user accounts. Allows uniform password and lifecycle policy.

Groups — clarity. Keeps role groups separate from users and computers.

Computers — policy. Allows workstation policy to apply cleanly.

Service Accounts — clarity. Keeps non-human accounts isolated for monitoring.

Disabled Users — policy. Holds leaver accounts. Supports audit retention.

Under Users
These OUs exist for delegation and clarity. They match the bank’s organizational structure.

Executive — delegation. Allows HR or IT to manage executive accounts separately.

Lending — clarity. Groups lending staff together for reporting.

Wire Operations — delegation. Supports separation of duties.

Wealth Management — clarity. Keeps high-risk roles visible.

Operations — clarity. Organizes back-office staff.

Compliance — delegation. Supports regulatory oversight.

IT — policy. Allows stricter controls for privileged users.

Retail Banking — clarity. Branch OUs beneath it allow delegation to branch managers.

3. Naming Conventions
Consistent naming supports automation and auditability.

Users: first initial + last name

Example: jsmith

Collision rule: use first two letters of first name + last name

Example: jdoe and jadoe

Service accounts: prefix svc-

Example: svc-corebanking

Groups: prefix ROLE-

Example: ROLE-LendingOfficer

Computers: WKS-SITE-NNN

Example: WKS-DAL-014

4. Collision Rule (Worked Example)
If two users share the same first initial and last name:

John Doe ? jdoe

Jane Doe ? jadoe

If a third collision occurs, IT adds a number:

James Doe ? jadoe2

This keeps names predictable and avoids random variations.

5. Required Attributes (and Why They Matter)
First Name / Last Name — identifies the person. Required for HR and audit.

EmployeeID — unique identity key. Used for automation and matching HR records.

Department — supports role assignment and reporting.

Title — helps validate access appropriateness.

Manager — supports approval workflows.

Status — active or terminated. Drives lifecycle actions.

Email — communication and identity verification.

Each attribute ensures the bank can prove who the user is and why they have access.

6. Access Model
Ironbridge uses a role-based access model.

Access is granted only through role groups.

Each account receives one role group.

No direct permissions are assigned to any user.

Role groups map to job functions, not individuals.

This model ensures access is tied to what the job requires, not personal preference.

7. Role Catalog Summary
The role catalog lists every role group and the access it provides.
It includes business roles (Lending Officer, Teller, Wire Operator) and technical roles (IT Support, System Admin).

Ownership:

Compliance owns the catalog.

IT maintains the technical implementation.

HR provides job titles and status changes.

Changes require approval from Compliance + IT.

8. Account States
Accounts can be:

Enabled — active employees.

Disabled — leavers or long-term leave.

Locked — security event or password retry limit.

Expired — temporary accounts past their end date.

Leavers are disabled, not deleted.  
This preserves audit history, supports investigations, and prevents accidental reuse.

Disabled accounts are moved to the Disabled Users OU.

9. Privileged Access Rules
Privileged access is tightly controlled.

Only IT staff may hold privileged roles.

Privileged accounts must be separate from normal user accounts.

All privileged access requires documented approval.

All privileged access is logged and monitored.

Exception Register:  
Any deviation from this standard must be recorded in the exception register, with:

Reason for exception

Duration

Approver

Compensating controls

Compliance reviews exceptions monthly.

10. Review Cadence and Document Owner
Owner: IT & Identity Specialist.

Review cadence: every 12 months, or after major organizational changes.

Updates require approval from Compliance and IT Management.