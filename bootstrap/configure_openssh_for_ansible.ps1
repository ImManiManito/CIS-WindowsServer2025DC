# Run locally as Administrator on the Windows Server if OpenSSH is not already using PowerShell.
# This script is language-agnostic and works on Windows Server in any language.

$sshd = Get-Service sshd -ErrorAction Stop
New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null

# Detect PowerShell path (works in any Windows language)
$systemRoot = $env:SystemRoot
$powershellPath = "$systemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

# Verify PowerShell exists
if (-not (Test-Path $powershellPath)) {
    Write-Error "PowerShell not found at: $powershellPath"
    exit 1
}

New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value $powershellPath -PropertyType String -Force | Out-Null
Restart-Service sshd
Write-Host "OpenSSH DefaultShell configured to: $powershellPath"
