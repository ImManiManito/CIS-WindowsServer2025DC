---
# LOCALIZED PATHS CONFIGURATION GUIDE
# Este proyecto ahora está configurado para trabajar con Windows Server 2025
# en cualquier idioma (Español, Inglés, Francés, Alemán, etc.)
#
# GUÍA DE RUTAS LOCALIZADAS - LOCALIZED PATHS GUIDE
#

## Descripción / Description

El rol ahora detecta automáticamente las rutas del sistema en tiempo de ejecución,
funcionando correctamente tanto en sistemas Windows en español como en cualquier otro idioma.

The role now automatically detects system paths at runtime, working correctly on
Windows systems in Spanish, English, or any other language.

## Variables de Rutas Detectadas / Detected Path Variables

Las siguientes variables se establecen automáticamente durante la tarea "preflight":
The following variables are automatically set during the "preflight" task:

| Variable | Description | Example (English) | Example (Spanish) |
|----------|-------------|-------------------|------------------|
| `cis_system_root` | Windows system root | C:\Windows | C:\Windows |
| `cis_users_path` | Users directory | C:\Users | C:\Usuarios |
| `cis_user_profile_path` | User profiles path | C:\Users | C:\Usuarios |
| `cis_program_files` | Program Files directory | C:\Program Files | C:\Archivos de programa |
| `cis_program_files_x86` | Program Files x86 | C:\Program Files (x86) | C:\Archivos de programa (x86) |
| `cis_programdata` | ProgramData directory | C:\ProgramData | C:\ProgramData |
| `cis_temp_path` | Temp directory | C:\Users\username\AppData\Local\Temp | C:\Usuarios\usuario\AppData\Local\Temp |
| `cis_powershell_path` | PowerShell executable | C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe | C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe |
| `cis_event_log_path` | Event logs directory | C:\Windows\System32\winevt\Logs | C:\Windows\System32\winevt\Logs |

## Uso en Playbooks / Usage in Playbooks

```yaml
# INCORRECTO - NOT RECOMMENDED (hardcoded paths):
- name: Example task
  win_shell: |
    Get-ChildItem "C:\Users\Administrator"

# CORRECTO - RECOMMENDED (using variables):
- name: Example task
  win_shell: |
    Get-ChildItem "{{ cis_users_path }}\Administrator"
```

## Personalización / Customization

Si necesitas agregar rutas adicionales, edita:
If you need to add additional paths, edit:

1. `roles/cis_windows_server_2025_l1_dc/vars/localized_paths.yml`
   - Variables estáticas que no cambian entre idiomas

2. `roles/cis_windows_server_2025_l1_dc/tasks/preflight.yml`
   - Agrega nuevas tareas `win_powershell` y `set_fact` para detectar rutas dinámicas

## Ejemplo de Extensión / Extension Example

```yaml
# En tasks/preflight.yml, agregue:
# In tasks/preflight.yml, add:

- name: Detect additional paths
  ansible.windows.win_powershell:
    script: |
      [pscustomobject]@{
        DocumentsPath = [Environment]::GetFolderPath("MyDocuments")
        DownloadsPath = [Environment]::GetFolderPath("Downloads")
      }
  register: cis_additional_paths

- name: Set additional paths as facts
  ansible.builtin.set_fact:
    cis_documents_path: "{{ cis_additional_paths.output[0].DocumentsPath }}"
    cis_downloads_path: "{{ cis_additional_paths.output[0].DownloadsPath }}"
```

## Soporte de Idiomas / Language Support

Windows localizará automáticamente las siguientes carpetas:
Windows will automatically localize the following folders:

| English | Español | Français | Deutsch |
|---------|---------|----------|---------|
| Users | Usuarios | Utilisateurs | Benutzer |
| Program Files | Archivos de programa | Fichiers programme | Programmdateien |
| Program Files (x86) | Archivos de programa (x86) | Fichiers programme (x86) | Programmdateien (x86) |

Sin embargo, `Windows` (la carpeta raíz), `ProgramData` y `System32` permanecen siempre en inglés
internamente por razones de compatibilidad del sistema.

However, `Windows` (root folder), `ProgramData`, and `System32` remain in English internally
for system compatibility reasons.

## Verificación / Verification

Para verificar que las rutas se detectaron correctamente:
To verify that paths were correctly detected:

```bash
# En la salida de Ansible, busca la tarea "Display detected system paths":
# In Ansible output, look for the "Display detected system paths" task:

System paths detected (language-agnostic detection):
- System Root: C:\Windows
- Users Path: C:\Usuarios (or C:\Users on English systems)
- Program Files: C:\Archivos de programa (or C:\Program Files)
- etc.
```
