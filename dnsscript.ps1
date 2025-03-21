# Set execution policy
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
    Write-Host "Execution policy successfully set to RemoteSigned."
} catch {
    Write-Host "Error setting execution policy. Continuing without changing the execution policy." -ForegroundColor Yellow
}
 
############################### Enabling SSL\TLS ############################
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
public bool CheckValidationResult(
ServicePoint srvPoint, X509Certificate certificate,
WebRequest request, int certificateProblem) {
return true;
}
}
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#############################################################################
 
$registryPath = "HKLM:\SOFTWARE\Amazon\SkyLight"
$propertyName = "DomainJoinDNS"
$propertyValue = ""
$serviceName = "SkyLightWorkspaceConfigService"
 
# Ensure the registry path exists
if (!(Test-Path $registryPath)) {
    Write-Host "Registry path does not exist. Adding the entries now." -ForegroundColor Yellow
	New-item -path "HKLM:\SOFTWARE\Amazon\"
	Start-sleep -milliseconds 500
	New-item -path "HKLM:\SOFTWARE\Amazon\SkyLight\"
	Write-Host "Registry path is added now. proceeding with the modification."
}
Else{	
	write-host "Registry exists on the workspace, deleting now" -foregroundcolor Red
	remove-item -path "HKLM:\SOFTWARE\Amazon\*"
 	start-sleep -milliseconds 500
 	New-item -path "HKLM:\SOFTWARE\Amazon\"
	Start-sleep -milliseconds 500
	New-item -path "HKLM:\SOFTWARE\Amazon\SkyLight\"
	Write-Host "Registry path is added now. proceeding with the modification."
     	
	write-host "Registry path exists. Proceeding with the modification."
	
}
 
# Grant Full Control to "ALL APPLICATION PACKAGES"
try {
    $acl = Get-Acl -Path $registryPath
    $allAppPackages = New-Object System.Security.Principal.NTAccount("ALL APPLICATION PACKAGES")
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($allAppPackages, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    Set-Acl -Path $registryPath -AclObject $acl
    Write-Host "Full Control granted to 'ALL APPLICATION PACKAGES' on $registryPath"
} catch {
    Write-Host "Failed to set permissions on registry path: $_" -ForegroundColor Red
    exit 1
}
 
# Set new registry value
try {
    Set-ItemProperty -Path $registryPath -Name $propertyName -Value $propertyValue -Force
    Write-Host "Registry updated successfully."
} catch {
    Write-Host "Failed to update registry: $_" -ForegroundColor Red
    exit 1
}
 
# Restart the service
try {
    Restart-Service -Name $serviceName -Force
    Write-Host "Service restarted successfully."
} catch {
    Write-Host "Failed to restart service: $_" -ForegroundColor Red
    exit 1
}
