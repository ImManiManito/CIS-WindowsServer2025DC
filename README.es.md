# CIS Microsoft Windows Server 2025 v2.1.0 L1 DC — Ansible por SSH

*[Read this document in English](README.md)*

Este repositorio proporciona un rol de Ansible que automatiza el benchmark **CIS Microsoft Windows Server 2025 v2.1.0 Nivel 1 Controlador de Dominio** por medio de SSH.

Fue generado a partir del archivo de auditoría Tenable/CIS `CIS_Microsoft_Windows_Server_2025_v2.1.0_L1_DC (1).audit` e implementa los controles que pueden aplicarse de forma segura como código. Tras aplicar la porción automatizada y documentar los ítems de revisión, el entorno alcanzó un **68.81% de cumplimiento** en un escaneo de Tenable.

Para la descripción completa de la arquitectura, referencia archivo por archivo e integración con otros proyectos, consulta [ARCHITECTURE.es.md](ARCHITECTURE.es.md) (también disponible [en inglés](ARCHITECTURE.md)).

## Arquitectura objetivo

```text
Nodo de control Ubuntu con Ansible
           |
           | SSH
           v
Windows Server 2025 Controlador de Dominio
           +-- Microsoft OpenSSH Server
           +-- DefaultShell = Windows PowerShell
           +-- Modulos ansible.windows / community.windows
```

No se requiere WinRM; Ansible se conecta mediante `ansible_connection=ssh` y ejecuta los módulos Windows sobre un shell de PowerShell.

## Modelo de seguridad

Los Controladores de Dominio son sistemas de alto impacto. El rol establece por defecto `cis_apply_domain_account_policy` y `cis_apply_user_rights` en `false`. Revise esas configuraciones antes de habilitarlas. Las configuraciones de registro y la política de auditoría avanzada están habilitadas por defecto.

## Cobertura generada a partir de la auditoría

- Ítems personalizados de auditoría: 325
- Configuraciones de registro a nivel máquina automatizadas: 194
- Valores de registro que deben estar ausentes: 3
- Subcategorías de política de auditoría avanzada: 34
- Controles de asignación de derechos de usuario: 38
- Controles de política de contraseñas: 7
- Controles de política de bloqueo: 3
- Controles de registro de contexto de usuario (HKU) reservados para revisión: 7
- Controles de registro complejos/condicionales reservados para revisión: 18

El archivo [control_manifest.yml](control_manifest.yml) lista los ítems que se dejaron intencionalmente para revisión en lugar de asumir semánticas condicionales o multi-valor.

## Requisitos

- Nodo de control Ubuntu con ansible-core 2.18 o superior.
- El objetivo Windows Server 2025 ya debe ser un Controlador de Dominio.
- Microsoft OpenSSH Server habilitado en el objetivo.
- Shell predeterminado de OpenSSH configurado en Windows PowerShell.
- La cuenta SSH debe ser administradora en el DC.
- Colecciones declaradas en `requirements.yml`.

Instalar colecciones:

```bash
ansible-galaxy collection install -r requirements.yml
```

Validar SSH:

```bash
ssh ansible-cis@DC_IP
```

Validar Ansible:

```bash
ansible windows_2025_dc -m ansible.windows.win_ping
```

## Secuencia recomendada de despliegue

Primero ejecute la validación de sintaxis y el modo de comprobación:

```bash
ansible-playbook site.yml --syntax-check
ansible-playbook site.yml --check --diff
```

Luego despliegue las categorías de bajo riesgo manteniendo deshabilitados los derechos de usuario y la política de dominio:

```bash
ansible-playbook site.yml
```

Después de validar aplicaciones y servicios, habilite los derechos de usuario explícitamente:

```bash
ansible-playbook site.yml -e cis_apply_user_rights=true
```

Habilite la política de contraseñas/bloqueo a nivel de dominio solo después de confirmar que la organización desea aplicar esos valores en la política de contraseñas predeterminada efectiva de AD:

```bash
ansible-playbook site.yml -e cis_apply_domain_account_policy=true
```

## Nota importante sobre el Controlador de Dominio

La auditoría CIS proporcionada señala explícitamente que la Política de Contraseñas y la Política de Bloqueo de Cuentas deben ser efectivas a nivel de dominio. Este rol utiliza `Set-ADDefaultDomainPasswordPolicy` en lugar de aplicar una política local `secedit` en un DC. Si su gobernanza requiere específicamente que estas configuraciones estén escritas en la **GPO Default Domain Policy** en lugar de aplicarse directamente al objeto de política de contraseñas predeterminada de AD, mantenga `cis_apply_domain_account_policy: false` y gestione esa GPO a través de su proceso aprobado de cambios de GPO.

## Banderas de funcionalidad

El rol se controla mediante banderas booleanas definidas en [roles/cis_windows_server_2025_l1_dc/defaults/main.yml](roles/cis_windows_server_2025_l1_dc/defaults/main.yml) y sobrescritas en [group_vars/windows_2025_dc.yml](group_vars/windows_2025_dc.yml) para este sitio:

| Bandera | Valor por defecto | Descripción |
|---------|-------------------|-------------|
| `cis_apply_domain_account_policy` | `false` | Establece la política de contraseñas/bloqueo predeterminada efectiva del dominio. De alto impacto; mantener deshabilitada hasta su aprobación. |
| `cis_apply_user_rights` | `false` | Reemplaza la lista completa de principios para cada derecho de usuario. Valide contra sus servicios antes de habilitarla. |
| `cis_apply_machine_registry` | `true` | Aplica 194 configuraciones de registro CIS a nivel máquina. |
| `cis_apply_registry_removals` | `true` | Elimina valores de registro que CIS exige que no existan. |
| `cis_apply_audit_policy` | `true` | Configura 34 subcategorías de política de auditoría avanzada. |
| `cis_apply_security_options` | `true` | Configura opciones de seguridad adicionales (traducción anónima SID/Nombre, cierre forzoso). |
| `cis_apply_account_renames` | `false` | Renombra las cuentas integradas Administrador e Invitado. |
| `cis_apply_logon_banner` | `false` | Configura el aviso legal de inicio de sesión. |

## Referencia rápida de variables

Tunables principales en `defaults/main.yml`:

| Variable | Valor por defecto | Propósito |
|----------|-------------------|-----------|
| `cis_administrator_account_name` | `CIS-Administrator-CHANGE-ME` | Nuevo nombre para la cuenta integrada Administrador (RID 500). |
| `cis_guest_account_name` | `CIS-Guest-CHANGE-ME` | Nuevo nombre para la cuenta integrada Invitado (RID 501). |
| `cis_legal_notice_caption` | `Authorized Use Only` | Título del aviso legal de inicio de sesión. |
| `cis_legal_notice_text` | *ver archivo* | Cuerpo del aviso legal de inicio de sesión. |
| `cis_domain_password_history` | `24` | Número de contraseñas únicas recordadas. |
| `cis_domain_max_password_age_days` | `365` | Vida máxima de la contraseña. |
| `cis_domain_min_password_age_days` | `1` | Vida mínima de la contraseña. |
| `cis_domain_min_password_length` | `14` | Longitud mínima de la contraseña. |
| `cis_domain_complexity_enabled` | `true` | Requerir complejidad de contraseña. |
| `cis_domain_reversible_encryption_enabled` | `false` | Almacenar contraseñas con cifrado reversible. |
| `cis_domain_lockout_duration_minutes` | `15` | Duración del bloqueo de cuenta. |
| `cis_domain_lockout_threshold` | `5` | Umbral de intentos fallidos de inicio de sesión. |
| `cis_domain_lockout_observation_window_minutes` | `15` | Ventana de observación del umbral de bloqueo. |

Revise y personalice estos valores en `group_vars/windows_2025_dc.yml` o páselos como variables extra antes de habilitar las categorías correspondientes.

## Advertencia sobre derechos de usuario

`win_user_right` con `action: set` reemplaza la lista completa de principios para ese privilegio. Esto está deshabilitado por defecto porque aplicaciones, software de respaldo, agentes de monitoreo, componentes de Exchange/IIS o identidades de servicio pueden requerir derechos adicionales. Revise `cis_user_rights` antes de habilitarlo.

## Qué no se automatiza

El rol deja intencionalmente algunos controles para revisión manual. Estos se listan en [control_manifest.yml](control_manifest.yml):

* **Controles de registro de contexto de usuario (7)** — Configuraciones HKU/HKCU como notificaciones emergentes en la pantalla de bloqueo, información de zona de archivos adjuntos y Windows Spotlight. Normalmente deben entregarse a través de una GPO de dominio/política de usuario en lugar de editarse oportunísticamente en perfiles cargados.
* **Controles de registro complejos/condicionales (18)** — Controles con requisitos multi-valor (por ejemplo, tuberías nombradas anónimas/compartidas, rutas de registro accesibles remotamente, NetBIOS, NTLM, firma LDAP, comportamiento del mensaje UAC, extracción de tarjeta inteligente) que requieren decisiones organizacionales antes de codificarlos.

Resolver estos ítems a través del proceso de cambios aprobado es necesario para superar el **68.81%** de cumplimiento actual.

## Solución de problemas

### La conexión SSH falla

* Confirme que OpenSSH Server esté instalado y en ejecución: `Get-Service sshd` en el DC.
* Confirme que el shell predeterminado sea PowerShell: `Get-ItemProperty 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell`.
* Ejecute [bootstrap/configure_openssh_for_ansible.ps1](bootstrap/configure_openssh_for_ansible.ps1) como Administrador si es necesario.

### `win_ping` falla con un error de shell

* Verifique `ansible_shell_type=powershell` y `ansible_shell_executable=powershell.exe` en el inventario.
* Asegúrese de que el usuario SSH sea miembro del grupo local Administradores en el DC.

### La tarea de política de auditoría falla en Windows en otro idioma

El rol evita los nombres localizados de subcategorías y llama a `auditpol` directamente usando GUIDs independientes del idioma. Si aún ve errores, verifique que el mapa `cis_audit_subcategory_guids` en `defaults/main.yml` incluya la subcategoría referenciada por el control que falla.

### Los derechos de usuario causan interrupciones de servicio

Si habilitar `cis_apply_user_rights=true` afecta una aplicación o servicio:

1. Identifique el privilegio afectado y la identidad de servicio faltante a partir de los registros o mensajes de error.
2. Agregue el SID o nombre de cuenta requerido a la entrada correspondiente de `cis_user_rights` dentro de `defaults/main.yml`.
3. Vuelva a aplicar con la bandera en `true`.

> Nota: `win_user_right` con `action: set` reemplaza la lista completa de principios, por lo que la lista `cis_user_rights` debe incluir explícitamente cada cuenta que necesite el privilegio.

## Próximos pasos

1. Revise la arquitectura completa y la guía operativa en [ARCHITECTURE.es.md](ARCHITECTURE.es.md).
2. Personalice `group_vars/windows_2025_dc.yml` y las variables en `roles/cis_windows_server_2025_l1_dc/defaults/main.yml`.
3. Resuelva los ítems listados en [control_manifest.yml](control_manifest.yml) a través de su proceso de cambios aprobado.
4. Ejecute la secuencia de despliegue anterior y verifique la puntuación de cumplimiento actualizada de Tenable.

## Sin reinicio automático

El rol nunca reinicia un Controlador de Dominio incondicionalmente. Programe cualquier reinicio requerido a través del proceso de mantenimiento/cambios de su DC.
