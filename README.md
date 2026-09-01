# CIS Microsoft Windows Server 2025 v2.1.0 L1 DC — Ansible over SSH

Generated from `CIS_Microsoft_Windows_Server_2025_v2.1.0_L1_DC (1).audit` for this architecture:

`Ubuntu Ansible control node -> SSH/OpenSSH -> PowerShell -> Windows Server 2025 Domain Controller`

## Safety model

Domain Controllers are high-impact systems. The role intentionally defaults `cis_apply_domain_account_policy` and `cis_apply_user_rights` to `false`. Review those settings before enabling them. Registry and Advanced Audit Policy settings are enabled by default.

## Coverage generated from the audit

- Audit custom items: 325
- Machine registry settings directly automated: 194
- Registry values required absent: 3
- Advanced Audit Policy subcategories: 34
- User Rights Assignment controls: 38
- User-context registry controls held for review: 7
- Complex/conditional registry checks held for review: 18

The `control_manifest.yml` file lists items intentionally held for review instead of guessing at conditional/multi-value semantics.

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

## User-context policies

CIS controls targeting HKU/HKCU are listed in `control_manifest.yml` rather than forced across whichever user hives happen to be loaded at runtime. For a Domain Controller these should normally be delivered through a domain GPO/user policy rather than opportunistically editing loaded profiles.

## No automatic reboot

The role never unconditionally reboots a Domain Controller. Schedule any required restart through your DC maintenance/change process.
