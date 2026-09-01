# Run locally as Administrator on the Windows Server if OpenSSH is not already using PowerShell.
$sshd = Get-Service sshd -ErrorAction Stop
New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force | Out-Null
Restart-Service sshd
