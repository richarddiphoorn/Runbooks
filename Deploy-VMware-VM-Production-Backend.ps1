Workflow Deploy-VMware-VM-Production-Backend
{
    <#
            Project Name: Deploy Frontend Windows Server
            Runbook Name: Deploy-VMware-VM-Production-Backend
            Runbook Type: Controller
            Runbook Tags: Type:Controller, Project:Deploy Backend Windows Server
            Runbook Description: Controller Runbook for the "Deploy Windows Server" Project
            Runbook Author: Richard Diphoorn
            Runbook Creation Date: 2015-05-01
    #>
    
    param (
        [Parameter()][string]$nodeName,
        [Parameter()][string]$nodeIPv4Address
    )
    $vmCluster				= Get-AutomationVariable -Name 'VMware-Prd-Cluster-DCF'
    $dataStoreCluster       = Get-AutomationVariable -Name 'VMware-Datastore-Cluster-Silver'
    $nodeDefaultFolder		= Get-AutomationVariable -Name 'VMware-Server-Folder'
    $nodePortgroup  		= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-Portgroup-'
    $nodeIPv4SubnetMask		= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-IPv4-Subnetmask-'
    $nodeIPv4Gateway		= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-IPv4-Gateway-'
    $nodeIPv4Dns1			= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-IPv4-DNS-Server-1'
    $nodeIPv4Dns2			= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-IPv4-DNS-Server-2'
    $vmTemplate				= Get-AutomationVariable -Name 'VMware-Templ-W2012R2'
    $specFullName			= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-FullName'
    $specOrgName			= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-OrgName'
    $specDomain				= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-Domain'
    $specTimezone			= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-Timezone'
    $specProductKey			= Get-AutomationVariable -Name 'VMware-Templ-W2012R2-ProductKey'
    $nodeLocalAdminPassword = Get-AutomationVariable -Name 'VMware-Templ-W2012R2-LocalAdmin-Password'
    $vmWareMgmtServer       = Get-AutomationVariable -Name 'VMware-vCenter-Server'
    $vmWareMgmtCred         = 'VMware-vCenter-Credentials'
    $domainJoinCred     	= 'Domain-Join-Credentials'
    $serverOU               = Get-AutomationVariable -Name 'Servers-OU'
    
    $PSdomainJoinCred       = Get-AutomationPSCredential -Name 'Domain-Join-Credentials'
    #Prestaging the Computer Object
    New-ADComputer -Name $nodeName -Path $serverOU -Enabled $True -Credential $PSdomainJoinCred
  
    $deployVM = Deploy-VMware-VM -nodeName $nodeName -nodeIPv4Address $nodeIPv4Address -vmCluster $vmCluster -dataStoreCluster $dataStoreCluster -nodeDefaultFolder $nodeDefaultFolder -nodePortgroup $nodePortgroup -nodeIPv4SubnetMask $nodeIPv4SubnetMask -nodeIPv4Gateway $nodeIPv4Gateway -nodeIPv4Dns1 $nodeIPv4Dns1 -nodeIPv4Dns2 $nodeIPv4Dns2 -vmTemplate $vmTemplate -specFullName $specFullName -specOrgName $specOrgName -specDomain $specDomain -specTimezone $specTimezone -specProductKey $specProductKey -nodeLocalAdminPassword $nodeLocalAdminPassword -vmWareMgmtServer $vmWareMgmtServer -vmWareMgmtCred $vmWareMgmtCred -domainJoinCred $domainJoinCred
}
