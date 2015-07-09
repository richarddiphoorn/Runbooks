Workflow Deploy-VMware-VM
{
    <#
            Project Name: Deploy Windows Virtual Machine
            Runbook Name: Deploy-VMware-VM
            Runbook Type: Tool
            Runbook Tags: Type:Tool, Project:Deploy Frontend Windows Server
            Runbook Description: Tool Runbook for the "Deploy Windows Server" Project
            Runbook Author: Richard Diphoorn
            Runbook Creation Date: 2015-05-01
    #>
    
    param (
        [Parameter()][string]$nodeName,
        [Parameter()][string]$nodeIPv4Address,
        [Parameter()][string]$vmCluster,
        [Parameter()][string]$dataStoreCluster,
        [Parameter()][string]$nodeDefaultFolder,
        [Parameter()][string]$nodePortgroup,
        [Parameter()][string]$nodeIPv4Subnetmask,
        [Parameter()][string]$nodeIPv4Gateway,
        [Parameter()][string]$nodeIPv4Dns1,
        [Parameter()][string]$nodeIPv4Dns2,
        [Parameter()][string]$vmTemplate,
        [Parameter()][string]$specFullName,
        [Parameter()][string]$specOrgName,
        [Parameter()][string]$specDomain,
        [Parameter()][string]$specTimezone,
        [Parameter()][string]$specProductKey,
        [Parameter()][string]$nodeLocalAdminPassword,
        [Parameter()][string]$domainJoinCred,
        [Parameter()][string]$vmWareMgmtServer,
        [Parameter()][string]$vmWareMgmtCred
    )
    
    $PSdomainJoinCred = Get-AutomationPSCredential -Name $domainJoinCred
    $PSvmWareMgmtCred = Get-AutomationPSCredential -Name $vmWareMgmtCred

    $deployVMwareVM = InlineScript{
        # Correcting the Environment Variable to the PowerCLI Module, due to a bug in the PowerCLI installer
        #Save the current value in the $p variable.
        $p = [Environment]::GetEnvironmentVariable('PSModulePath')

        #Add the new path to the $p variable. Begin with a semi-colon separator.
        $p += ';D:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Modules\'

        #Add the paths in $p to the PSModulePath value.
        [Environment]::SetEnvironmentVariable('PSModulePath',$p)

        Import-Module -Name VMware.VimAutomation.Core
        
        # Connect to the VMware vCenter Server
        Connect-VIServer -Server $using:vmWareMgmtServer -Credential $using:PSvmWareMgmtCred -ErrorAction Stop
        
        # Code block for getting the datastore with most free space. The variable $largestDataStore is used.
        $tmpDataStores = Get-DatastoreCluster -Name $using:dataStoreCluster | Get-Datastore
        $largestFreeSpace = '0'
        $largestDatastore = $null

        foreach ($tmpDataStore in $tmpDataStores)
        {
            if ($tmpDataStore.FreeSpaceGB -gt $largestFreeSpace ) 
                {
                $largestFreeSpace = $tmpDataStore.FreeSpaceGB
                $largestDatastore = $tmpDataStore
                }
        }
        # End of code block.

        $resPool 	= Get-Cluster -Name $using:vmCluster | Get-ResourcePool
        $vmHost 	= Get-Cluster -Name $using:vmCluster | Get-VMHost | Get-Random
        $vmFolder	= Get-Folder -Id $using:nodeDefaultFolder
        $dataStore 	= $largestDataStore

        # 1. Create a simple customizations spec:
        $custSpec 	= New-OSCustomizationSpec -FullName $using:specFullName -OrgName $using:specOrgName -OSType Windows -ChangeSid -AdminPassword $using:nodeLocalAdminPassword -Domain $using:specDomain -DomainCredentials $using:PSdomainJoinCred -TimeZone $using:specTimezone -ProductKey $using:specProductKey -LicenseMode PerSeat
 
        # 2. Modify the default network customization settings:
        $custSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $using:nodeIPv4Address -SubnetMask $using:nodeIPv4SubnetMask -Dns $using:nodeIPv4Dns1,$using:nodeIPv4Dns2 -DefaultGateway $using:nodeIPv4Gateway
 
        # 3. Deploy a VM from a template using the newly created customization:
        $vmCloneTask = New-VM -Name $using:nodeName -Template $using:vmTemplate -VMHost $vmHost -OSCustomizationSpec $using:custSpec -ResourcePool $resPool -Datastore $dataStore -Location $vmFolder -RunAsync
        
        # 4. Monitor the clone VM task, and after that we continue 
        while($vmCloneTask.ExtensionData.Info.State -eq 'running'){
            Start-Sleep 1
            $vmCloneTask.ExtensionData.UpdateViewData('Info.State')
        }

        # 5. Move the VM to the correct Port Group
        Get-VM -Name $using:nodeName | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $using:nodePortgroup -Confirm:$false
        
        # 6. First we wait 5 seconds, to give the previous task the time to finish, and then we can start the VM
        Start-Sleep 5
        Get-VM -Name $using:nodeName | Start-VM -RunAsync -Confirm:$false
    }

    $deployVMwareVM
}
