# IB-STD-001 — Directory Standard

**Ironbridge Bank & Trust**

**Domain:** `ironbridge.local`

**Owner:** IT & Identity Specialist

---

## 1. Purpose and Scope

This standard establishes the operational requirements for structuring and managing the Ironbridge Bank & Trust directory service.

* **Primary Objective:** Ensure the bank can definitively answer who has access and why, directly remediating **MRA #1**.
* **Scope:** Applies universally to all users, service accounts, computers, and security groups within the `ironbridge.local` domain.
* **Benefits:** Enhances operational consistency, simplifies regulatory audits, and reduces overall identity risk.

---

## 2. Organizational Unit (OU) Design

Every OU is intentionally deployed to serve a specific administrative function: policy enforcement, security delegation, or organizational clarity.

### Top-Level OUs

| OU Name | Primary Purpose | Description & Function |
| --- | --- | --- |
| **Users** | Policy | Houses all human user accounts to enable uniform password and lifecycle policies. |
| **Groups** | Clarity | Isolates role-based security groups away from user and computer objects. |
| **Computers** | Policy | Enables clean, centralized application of workstation security policies. |
| **Service Accounts** | Clarity | Isolates non-human accounts for dedicated monitoring and auditing. |
| **Disabled Users** | Policy | Stores deactivated leaver accounts to maintain required audit retention history. |

### Sub-OUs Under `Users`

Structured to match the bank's organizational hierarchy, supporting granular delegation and structural clarity:

* **Executive:** Enables dedicated management of executive accounts by HR or senior IT.
* **Lending:** Groups lending personnel together for streamlined reporting.
* **Operations:** Organizes back-office administrative staff.
* **Retail Banking:** Features branch-specific sub-OUs, allowing delegation of administrative tasks directly to branch managers.
* **Wealth Management:** Isolates high-risk roles for heightened visibility.
* **Compliance:** Supports targeted regulatory oversight and delegation.
* **IT:** Implements strict security controls specifically tailored for privileged users.
* **Wire Operations:** Enforces strict separation of duties.

---

## 3. Naming Conventions

Enforcing strict naming conventions supports automation, predictability, and auditability.

* **Standard Users:** First initial and last name (e.g., `jsmith`).
* *Collision Rule:* If a name collision occurs, use the first **two** letters of the first name (e.g., `jdoe` and `jadoe`). If a third collision occurs, append a sequential number (e.g., `jadoe2`).


* **Service Accounts:** Prefixed with `svc-` (e.g., `svc-corebanking`).
* **Role Groups:** Prefixed with `ROLE-` (e.g., `ROLE-LendingOfficer`).
* **Workstations:** Structured as `WKS-SITE-NNN` (e.g., `WKS-DAL-014`).

---

## 4. Required User Attributes

To prove user identity and justify system access, all directory accounts must populate the following attributes:

* **First & Last Name:** Identifies the individual; mandatory for HR verification and audits.
* **Employee ID:** Serves as the unique identity key for automated provisioning and HR reconciliation.
* **Department & Title:** Supports role assignment, reporting, and access appropriateness validation.
* **Manager:** Establishes reporting chains for approval workflows.
* **Status:** Designates active or terminated state to drive automated lifecycle actions.
* **Email:** Facilitates communications and identity verification.

---

## 5. Access Control Model

Ironbridge enforces a strict **Role-Based Access Control (RBAC)** model.

* **Indirect Permissions:** Access is granted exclusively through role groups mapped to job functions, never to individual users.
* **Mapping Limit:** Each account is assigned precisely one role group aligned with its operational responsibilities.
* **Account States:**
* **Enabled:** Active employees.
* **Disabled:** Departed employees or staff on extended leave. *(Leaver accounts are disabled rather than deleted to preserve audit history, support investigations, and prevent accidental username reuse).*
* **Locked:** Triggered by security events or password retry limits.
* **Expired:** Temporary accounts past their designated end date.



---

## 6. Role Catalog and Governance

The Role Catalog defines every approved role group and its associated access rights, encompassing both business roles (e.g., Teller, Lending Officer) and technical roles (e.g., IT Support, System Administrator).

### Governance Responsibilities

* **Compliance:** Owns the catalog and approves changes.
* **IT:** Maintains technical implementation and approves changes.
* **HR:** Provides authoritative job titles and status changes.

---

## 7. Privileged Access Rules

Privileged access presents heightened risk and is subjected to strict controls:

1. **Restriction:** Only authorized IT staff may hold privileged roles.
2. **Account Separation:** Privileged accounts must remain strictly distinct from standard user accounts.
3. **Approval & Monitoring:** All privileged access requires documented pre-approval and is continuously logged and monitored.

### Exception Register

Any deviation from this standard requires formal logging in the exception register, including:

* Justification for the exception
* Approved duration
* Designating approver
* Defined compensating controls
* **Review Cycle:** Compliance reviews all active exceptions on a monthly basis.

---

## 8. Document Administration

* **Owner:** IT & Identity Specialist
* **Review Cadence:** Conducted every 12 months or immediately following major organizational changes.
* **Change Approvals:** Updates require formal sign-off from both Compliance and IT Management.

---

*Would you like to adjust any of the naming conventions or add specific department sub-OUs before finalizing this standard?*