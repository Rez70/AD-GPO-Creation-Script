<#
.SYNOPSIS
    Creates new Group Policy Objects (GPO) and configures them 
    with the specified policies and permissions.

.DESCRIPTION
    Creates new GPOs with the provided names and comments.
    Links them to the specified OU path.
    Configures them with policies based on the given registry values.
    Sets read-only permissions for the authenticated users.
    Sets apply group policy permissions for the specified targets.
    Displays the permissions for verification.
    Creates a new folder and exports the GPO reports to it.

    The script takes input from a CSV file containing values for the following columns:
    - name
    - comment
    - ou
    - key
    - valuename
    - targetname
    - targettype
    - folderpath
    - filename

.PARAMETER CSVFile
    Holds the details for the creation of new GPOs. 
    Ensure a value is provided for each column.
    This is a mandatory parameter

.EXAMPLE
    Example usage:
    PS> .\New-GPOs.ps1 -CSVFile C:\Users\Administrator\Downloads\GPOCSV.txt

.NOTES
    Author: Abhiraj Singh
    Created: 2026-03-21
    Version: 1.0
    Last Modified: 2026-03-23
    Change Log:
        1.0 - Initial release
        1.1 - Implemented try/catch statements 

.LINK
    https://github.com/Rez70/AD-GPO-Creation-Script.git
#>

#Parameters

param(
[Parameter(Mandatory)]$CSVFile
)


#Functions

function New-ADGPO {
    [CmdletBinding()]
    param(
    [Parameter(Mandatory)]
    [psobject]$NewGPO)

    try{
        $gpo = New-GPO -Name $NewGPO.name -comment $NewGPO.comment -Verbose -ErrorAction Stop
    }
    catch {
        Write-Warning "$PSItem `nFunction: New-ADGPO`n"
    }

    try {
        New-GPLink -Name $gpo.DisplayName -Target $NewGPO.ou -LinkEnabled Yes -Enforced No -Verbose -ErrorAction Stop   
    }
    catch {
        Write-Warning "$PSItem `nFunction: New-ADGPO`n"
    }
}

function Set-GPORegistryPolicies {
    [CmdletBinding()]
    param(
    [Parameter(Mandatory)]
    [psobject]$NewGPO)

    try {
        Set-GPRegistryValue -Name $NewGPO.name -Key $NewGPO.key -ValueName $NewGPO.valuename -Type DWord -Value 1 -Verbose -ErrorAction Stop    
    }
    catch {
        Write-Warning "$PSItem `nFunction: Set-GPORegistryPolicies`n"
    }
    
}

function Set-GPOPermissions {
    [CmdletBinding()]
    param(
    [Parameter(Mandatory)]
    [psobject]$NewGPO)

    try {
        Set-GPPermission -Name $NewGPO.name -TargetName "Authenticated Users" -TargetType Group -PermissionLevel GpoRead -ErrorAction Stop
    }
    catch {
        Write-Warning "$PSItem `nFunction: Set-GPOPermissions`n"
    }
        
    try {
        Set-GPPermission -Name $NewGPO.name -TargetName $NewGPO.targetname -TargetType $NewGPO.targettype -PermissionLevel GpoApply -Verbose -ErrorAction Stop
    }
    catch {
        Write-Warning "$PSItem `nFunction: Set-GPOPermissions"
    }


    Get-GPPermission -Name $NewGPO.name -All | Format-Table Trustee,Permission -Verbose -ErrorAction Stop
}

function Export-GPOReports {
    [CmdletBinding()]
    param(
    [Parameter(Mandatory)]
    [psobject]$NewGPO)

    try {
        New-Item -ItemType Directory -Force -Path $NewGPO.folderpath | Out-Null -Verbose -ErrorAction Stop
    }
    catch {
        Write-Warning "$PSItem `nFunction: Export-GPOReports`n"
    }

    try {
        Get-GPOReport -Name $NewGPO.name -ReportType Html -Path "$($NewGPO.folderpath)\$($NewGPO.filename).html" -Verbose -ErrorAction Stop
    }
    catch {
        Write-Warning "$PSItem `nFunction: Export-GPOReports`n"
    }

    try {
        Get-GPOReport -Name $NewGPO.name -ReportType Xml -Path "$($NewGPO.folderpath)\$($NewGPO.filename).xml" -Verbose -ErrorAction Stop
    }
    catch {
        Write-Warning "$PSItem `nFunction: Export-GPOReports"
    }
}


#Execution Code

try {
    $GPOs = Import-Csv $CSVFile 
}
catch {
    Write-Warning "Could not find file. Please ensure the provided file path is correct."
    exit
}


foreach ($gpo in $GPOs) {
    

    if ($gpo.name -and $gpo.comment -and $gpo.ou -and $gpo.key -and $gpo.valuename -and $gpo.targetname -and $gpo.targettype -and $gpo.folderpath -and $gpo.filename) {

        New-ADGPO -NewGPO $gpo 
        Set-GPORegistryPolicies -NewGPO $gpo
        Set-GPOPermissions -NewGPO $gpo
        Export-GPOReports -NewGPO $gpo
    }
    else {
        Write-Warning "The CSV file contains missing values. please ensure a value is provided for each parameter."
        exit
    }      
}