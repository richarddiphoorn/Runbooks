#requires -Modules psftp
workflow Maintenance-FTP-Import
{
    <#
            Project Name: Maintenance
            Runbook Name: NHL-Maintenance-FTP-Import-FMSPRS
            Runbook Type: Tool
            Runbook Tags: Type:Process, Proj:Maintenance FTP Import
            Runbook Description: Process Runbook for the FTP Import
            Runbook Author: Richard Diphoorn
            Runbook Creation Date: 2015-06-05
    #>
    
    $ftpServer = Get-AutomationVariable -Name 'FTP-Import-FTP-Server'
    $ftpCredentials = Get-AutomationPSCredential -Name 'FTP-FTP-Credentials'
    $ftpStaging = Get-AutomationVariable -Name 'FTP-Import-FTP-Staging'
    $ftpDestination = Get-AutomationVariable -Name 'FTP-Import-FTP-Destination'
    $psUserCred = Get-AutomationPSCredential -Name 'SMA-Admin'
    $psDriveName = 'FMSPRS'

    $ftpJob = InlineScript{
        # 01. Importing the module and setting up a FTP connection, setting up PS Drive and defining variables
        If (!(Get-Module -Name PSFTP))
        {
            Import-Module -Name PSFTP
        }

        Set-FTPConnection -Credentials $using:ftpCredentials -Server $using:ftpServer -Session 'ftpSession' -UsePassive
        $Session = Get-FTPConnection -Session 'ftpSession'
        
        New-PSDrive -Name $using:psDriveName -PSProvider FileSystem -Root $using:ftpDestination -Credential $using:psUserCred

        # 02. Downloading FTP items from source
        Get-FTPChildItem -Session $Session | Get-FTPItem -Session $Session -LocalPath $using:ftpStaging -Overwrite

        # 03. Unzipping the FTP items into the staging directory
        #requires -Version 2
        function Expand-ZIPFile()
        {
            [CmdletBinding()]
            Param(

                [Parameter(Mandatory = $true,Position = 0)][string]$SourcePath,
                [Parameter(Mandatory = $true,Position = 2)][string]$DestinationPath,
                [Parameter(Position = 3)][bool]$Overwrite
            )

            Add-Type -AssemblyName System.IO.Compression.FileSystem

            try
            {
                foreach($sourcefile in (Get-ChildItem -Path $SourcePath -Filter '*.ZIP')) 
                {
                    $entries = [IO.Compression.ZipFile]::OpenRead($sourcefile.FullName).Entries
        
                    $entries | ForEach-Object -Process {
                        [IO.Compression.ZipFileExtensions]::ExtractToFile($_,"$DestinationPath\$_",$Overwrite)
                    }
                }
            }
        
            catch
            {
                Write-Warning -Message $_.Exception.Message
            }
        }
        
        Expand-ZIPFile -SourcePath $using:ftpStaging -Destinationpath $using:ftpStaging
        
        # 04. Copying the database files to the Cognos servers
        Copy-Item -Path "$using:ftpStaging\*" -Filter '*.bak' -Destination "$using:psDriveName`:" -Force -Confirm:$false 
        
        # 05. Cleaning up the Staging Directory
        Get-ChildItem -Path "$using:ftpStaging\*" | Remove-Item -Force -Confirm:$false
    }
    $ftpJob
}
