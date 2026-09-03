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

## Advertencia sobre derechos de usuario

`win_user_right` con `action: set` reemplaza la lista completa de principios para ese privilegio. Esto está deshabilitado por defecto porque aplicaciones, software de respaldo, agentes de monitoreo, componentes de Exchange/IIS o identidades de servicio pueden requerir derechos adicionales. Revise `cis_user_rights` antes de habilitarlo.

## Políticas de contexto de usuario

Los controles CIS dirigidos a HKU/HKCU se listan en `control_manifest.yml` en lugar de forzarse sobre las colmenas de usuario que estén cargadas en el momento de la ejecución. Para un Controlador de Dominio, estas normalmente deben entregarse a través de una GPO de dominio/política de usuario en lugar de editar oportunísticamente los perfiles cargados.

## Sin reinicio automático

El rol nunca reinicia un Controlador de Dominio incondicionalmente. Programe cualquier reinicio requerido a través del proceso de mantenimiento/cambios de su DC.
