# Purpose: Sets up the Server and Workstations OUs

$ip=$args[0]
$dc_name=$args[1]
$domain=$args[2]

$dc1,$dc2=$domain.split('.')

Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Checking AD services status..."
$svcs = "adws","dns","kdc","netlogon"
Get-Service -name $svcs -ComputerName localhost | Select Machinename,Name,Status

# Hardcoding DC hostname in hosts file
Add-Content "c:\windows\system32\drivers\etc\hosts" "        $ip    $dc"

# Force DNS resolution of the domain
ping /n 1 $dc_name.$domain
ping /n 1 $domain


Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Creating Server and Workstation OUs..."
# Create the Servers OU if it doesn't exist
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Creating Server OU"
try {
  Get-ADOrganizationalUnit -Identity "OU=Servers,DC=$dc1,DC=$dc2" | Out-Null
  Write-Host "Servers OU already exists. Moving On."
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
  New-ADOrganizationalUnit -Name "Servers" -Server "$dc_name.$domain"
}

# Create the Workstations OU if it doesn't exist
Write-Host "$('[{0:HH:mm}]' -f (Get-Date)) Creating Workstations OU"
try {
  Get-ADOrganizationalUnit -Identity "OU=Workstations,DC=$dc1,DC=$dc2" | Out-Null
  Write-Host "Workstations OU already exists. Moving On."
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
  New-ADOrganizationalUnit -Name "Workstations" -Server "$dc_name.$domain"
}

# Sysprep breaks auto-login. Let's restore it here:
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value 1
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -Value "vagrant"
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Value "vagrant"
