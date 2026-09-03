# CIS Microsoft Windows Server 2025 v2.1.0 L1 DC — Ansible over SSH

*[Leer este documento en español](README.es.md)*

This repository provides an Ansible role that automates the **CIS Microsoft Windows Server 2025 v2.1.0 Level 1 Domain Controller** benchmark over SSH.

It was generated from the Tenable/CIS audit file `CIS_Microsoft_Windows_Server_2025_v2.1.0_L1_DC (1).audit` and implements the controls that can be safely applied as code. After applying the automated portion and documenting the review items, the environment reached a **68.81% compliance score** on a Tenable scan.

For the full architecture description, file-by-file reference, and integration notes, see [ARCHITECTURE.md](ARCHITECTURE.md) (also available [in Spanish](ARCHITECTURE.es.md)).

## Target architecture

```text
Ubuntu Ansible control node
           |
           | SSH
           v
Windows Server 2025 Domain Controller
           +-- Microsoft OpenSSH Server
           +-- DefaultShell = Windows PowerShell
           +-- ansible.windows / community.windows modules
```

No WinRM is required; Ansible connects through `ansible_connection=ssh` and executes Windows modules over a PowerShell shell.

## Safety model

Domain Controllers are high-impact systems. The role intentionally defaults `cis_apply_domain_account_policy` and `cis_apply_user_rights` to `false`. Review those settings before enabling them. Registry and Advanced Audit Policy settings are enabled by default.

## Coverage generated from the audit

- Audit custom items: 325
- Machine registry settings directly automated: 194
- Registry values required absent: 3
- Advanced Audit Policy subcategories: 34
- User Rights Assignment controls: 38
- Password policy checks: 7
- Lockout policy checks: 3
- User-context registry controls held for review: 7
- Complex/conditional registry checks held for review: 18

The [control_manifest.yml](control_manifest.yml) file lists items intentionally held for review instead of guessing at conditional/multi-value semantics.

## Requirements

- Ubuntu control node with ansible-core 2.18 or newer.
- Windows Server 2025 target is already a Domain Controller.
- Microsoft OpenSSH Server enabled on the target.
- OpenSSH default shell set to Windows PowerShell.
- SSH account must be an administrator on the DC.
- Collections in `requirements.yml`.

Install collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Validate SSH:

```bash
ssh ansible-cis@DC_IP
```

Validate Ansible:

```bash
ansible windows_2025_dc -m ansible.windows.win_ping
```

## Recommended deployment sequence

First run syntax/check validation:

```bash
ansible-playbook site.yml --syntax-check
ansible-playbook site.yml --check --diff
```

Then deploy low-risk categories with high-impact rights/domain policy still disabled:

```bash
ansible-playbook site.yml
```

After application/service validation, enable User Rights explicitly:

```bash
ansible-playbook site.yml -e cis_apply_user_rights=true
```

Enable the domain-wide password/lockout policy only after confirming the organization wants these values applied to the effective default AD domain policy:

```bash
ansible-playbook site.yml -e cis_apply_domain_account_policy=true
```

## Important Domain Controller note

The supplied CIS audit explicitly notes that Password Policy and Account Lockout Policy must be effective at domain level. This role uses `Set-ADDefaultDomainPasswordPolicy` instead of applying a local `secedit` password policy to a DC. If your governance specifically requires the settings to be authored in the **Default Domain Policy GPO** rather than applied directly to the AD default domain password-policy object, keep `cis_apply_domain_account_policy: false` and manage that GPO through your approved GPO change process.

## User Rights warning

`win_user_right` with `action: set` replaces the complete principal list for that privilege. This is intentionally disabled by default because applications, backup software, monitoring agents, Exchange/IIS components, or service identities can require additional rights. Review `cis_user_rights` before enabling it.

## Feature flags

The role is controlled through boolean flags defined in [roles/cis_windows_server_2025_l1_dc/defaults/main.yml](roles/cis_windows_server_2025_l1_dc/defaults/main.yml) and overridden in [group_vars/windows_2025_dc.yml](group_vars/windows_2025_dc.yml) for this site:

| Flag | Default | Description |
|------|---------|-------------|
| `cis_apply_domain_account_policy` | `false` | Sets the effective default domain password/lockout policy. High-impact; keep disabled until approved. |
| `cis_apply_user_rights` | `false` | Replaces the complete principal list for each user right. Validate against your services before enabling. |
| `cis_apply_machine_registry` | `true` | Applies 194 CIS machine registry settings. |
| `cis_apply_registry_removals` | `true` | Removes registry values that CIS requires to be absent. |
| `cis_apply_audit_policy` | `true` | Configures 34 Advanced Audit Policy subcategories. |
| `cis_apply_security_options` | `true` | Sets additional security options (anonymous SID/Name translation, force logoff). |
| `cis_apply_account_renames` | `false` | Renames built-in Administrator and Guest accounts. |
| `cis_apply_logon_banner` | `false` | Configures the legal notice logon banner. |

## Variable quick reference

Key tunables in `defaults/main.yml`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `cis_administrator_account_name` | `CIS-Administrator-CHANGE-ME` | New name for the built-in Administrator account (RID 500). |
| `cis_guest_account_name` | `CIS-Guest-CHANGE-ME` | New name for the built-in Guest account (RID 501). |
| `cis_legal_notice_caption` | `Authorized Use Only` | Title of the legal notice logon banner. |
| `cis_legal_notice_text` | *see file* | Body of the legal notice logon banner. |
| `cis_domain_password_history` | `24` | Number of unique passwords remembered. |
| `cis_domain_max_password_age_days` | `365` | Maximum password age. |
| `cis_domain_min_password_age_days` | `1` | Minimum password age. |
| `cis_domain_min_password_length` | `14` | Minimum password length. |
| `cis_domain_complexity_enabled` | `true` | Require password complexity. |
| `cis_domain_reversible_encryption_enabled` | `false` | Store passwords using reversible encryption. |
| `cis_domain_lockout_duration_minutes` | `15` | Account lockout duration. |
| `cis_domain_lockout_threshold` | `5` | Failed logon threshold. |
| `cis_domain_lockout_observation_window_minutes` | `15` | Observation window for lockout threshold. |

Review and customize these values in `group_vars/windows_2025_dc.yml` or pass them as extra vars before enabling the corresponding categories.

## What is not automated

The role intentionally leaves some controls for manual review. These are listed in [control_manifest.yml](control_manifest.yml):

* **User-context registry controls (7)** — HKU/HKCU settings such as toast notifications, attachment zone information, and Windows Spotlight. These should normally be delivered through a domain GPO/user policy rather than edited opportunistically on loaded profiles.
* **Complex/conditional registry checks (18)** — Controls with multi-value requirements (e.g., anonymous named pipes/shares, accessible registry paths, NetBIOS, NTLM, LDAP signing, UAC prompt behavior, smart card removal) that require organizational decisions before hard-coding.

Resolving these items through your approved change process is required to move the compliance score beyond the current **68.81%**.

## Troubleshooting

### SSH connection fails

* Confirm OpenSSH Server is installed and running: `Get-Service sshd` on the DC.
* Confirm the default shell is PowerShell: `Get-ItemProperty 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell`.
* Run [bootstrap/configure_openssh_for_ansible.ps1](bootstrap/configure_openssh_for_ansible.ps1) as Administrator if needed.

### `win_ping` fails with a shell error

* Verify `ansible_shell_type=powershell` and `ansible_shell_executable=powershell.exe` in the inventory.
* Ensure the SSH user is a member of the local Administrators group on the DC.

### Audit policy task fails on non-English Windows

The role avoids localized subcategory names and calls `auditpol` directly using locale-independent GUIDs. If you still see errors, verify that the `cis_audit_subcategory_guids` map in `defaults/main.yml` includes the subcategory referenced by the failing control.

### User Rights cause service outages

If enabling `cis_apply_user_rights=true` breaks an application or service:

1. Identify the affected privilege and the missing service identity from the application logs or error message.
2. Add the required SID or account name to the relevant entry in `cis_user_rights` inside `defaults/main.yml`.
3. Re-apply with the flag set to `true`.

> Note: `win_user_right` with `action: set` replaces the entire principal list, so the `cis_user_rights` list must explicitly include every account that needs the privilege.

## Next steps

1. Review the full architecture and operational guidance in [ARCHITECTURE.md](ARCHITECTURE.md).
2. Customize `group_vars/windows_2025_dc.yml` and the variables in `roles/cis_windows_server_2025_l1_dc/defaults/main.yml`.
3. Resolve the items listed in [control_manifest.yml](control_manifest.yml) through your approved change process.
4. Run the deployment sequence above and verify the updated Tenable compliance score.

## No automatic reboot

The role never unconditionally reboots a Domain Controller. Schedule any required restart through your DC maintenance/change process.
