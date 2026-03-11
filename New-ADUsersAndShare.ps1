<#
.SYNOPSIS
    Creates Active Directory users and applies folder permissions.

.DESCRIPTION
    Takes input values from a CSV file and creates Active Directory user accounts.
    Takes input for the new folder path to be created.
    Takes input for the SMB share name.
    Applies NTFS and SMB share permissions to the created folder for the new user accounts.
     
    The CSV File must include the following columns:
    - firstname 
    - lastname 
    - username 
    - password 
    - accesstype
    - permissiontype
    - accessright

.PARAMETER CSVFile
    Specifies a path to a CSV file containing information on user accounts.
    This parameter is mandatory.

.PARAMETER NewFolderPath
    Specifies a path to the new folder.
    This parameter is mandatory.

.PARAMETER SmbShareName
    Specifies the name to be assigned to the new SMB share.
    This parameter is mandatory.

.EXAMPLE
    Example usage:
    PS> .\New-ADUsersAndShare.ps1 -CSVFile C:\Users\Administrator\Documents\CSV-Lab7.txt 
    -NewFolderPath C:\newfolder -SmbShareName NewSMBShare

.NOTES
    Author: Abhiraj Singh
    Created: 2026-03-07
    Version: 1.0
    Last Modified: 2026-03-09
    Change Log:
        1.0 - Initial release

.LINK
    https://github.com/Rez70/AD-User-Folder-Permissions.git
#>

#Parameters

param(
[parameter(Mandatory)]
[String]$CSVFile,
[parameter(Mandatory)]
[String]$NewFolderPath,
[parameter(Mandatory)]
[String]$SmbShareName)


#Functions

# Creates user accounts depending on the infomation provided in the CSV file
function Create-User {
    
    param(
    [parameter(Mandatory)]
    [psobject]$User)

    if (Get-ADUser -Filter "SamAccountName -eq '$($User.username)'") {
        Write-Output "User already exists!"
    }

    else {
        New-ADUser `
        -Name "$($User.firstname) $($User.lastname)" `
        -SamAccountName $User.username `
        -UserPrincipalName "$($User.username)@abhiraj.local" `
        -GivenName $User.firstname `
        -surname $User.lastname `
        -DisplayName "$($User.lastname), $($User.firstname)" `
        -AccountPassword (ConvertTo-SecureString $User.password -AsPlainText -Force) `
        -ChangePasswordAtLogon $true `
        -Enabled $true `
        -Verbose
    }
}

# Creates a new folder on the specified path
function Create-Folder {
    
    param(
    [String]$Folder)

    New-Item -Path "$($Folder)" –itemtype Directory -Verbose

}

# Assigns NTFS and SMB share folder permissions to users
function Set-Permissions {
    [CmdletBinding()]
    param(
    [parameter(Mandatory)]
    [psobject]$File,
    [String]$Folder,
    [String]$SmbName)

    foreach($User in $File) {
        $user = $User.username
        $accesstype = $User.accesstype
        $alloworDeny = $User.permissiontype
        $argList = $user,$accesstype,$alloworDeny
        $acl = Get-Acl $Folder
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule -ArgumentList $argList
        $acl.SetAccessRule($AccessRule)
        $acl | Set-Acl $Folder -Verbose
    }

    New-SmbShare -Name $SmbName -path $Folder -Verbose
    
    foreach($User in $File) {
        Grant-SmbShareAccess -Name $SmbName -AccountName $User.username -AccessRight $User.accessright -Force -Verbose
    }
}


#Execution Code

Import-Module ActiveDirectory

$CSVData = Import-csv $CSVFile

foreach($row in $CSVData) {
    Create-User -User $row
}

Create-Folder -Folder $NewFolderPath

Set-Permissions -File $CSVData -Folder $NewFolderPath -SmbName $SmbShareName


