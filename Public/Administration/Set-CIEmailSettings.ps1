function Set-CIEmailSettings(){
    <#
    .SYNOPSIS
    Sets the Email Settings on the currently connected Cloud Director Service.

    .DESCRIPTION
    Sets the Email Settings on the currently connected Cloud Director Service.

    .PARAMETER SystemScope
    Sets the Global Default settings in the System Scope (requires System Administrator rights)

    .PARAMETER Organisation
    The Cloud Director Organisation

    .PARAMETER senderEmailAddress
    The sender email address

    .PARAMETER smtpSettings
    A hashtable containing the SMTP Server Settings - requires the Keys "smtpServerName", "smtpServerPort" and "useAuthentication"

    .PARAMETER alertEmailTo
    The recipient email address

    .PARAMETER emailSubjectPrefix
    A prefix for the email subject

    .PARAMETER alertEmailToAllAdmins
    If true all Administrators will recieve the alerts

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-01-14
    VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True, ParameterSetName = "System")]
            [switch] $SystemScope,
        [Parameter(Mandatory=$True, ParameterSetName = "Organisation")]
            [ValidateNotNullorEmpty()] [string] $Organisation,
        [Parameter(Mandatory=$True, ParameterSetName = "System")]
        [Parameter(Mandatory=$True, ParameterSetName = "Organisation")]
            [ValidateNotNullorEmpty()] [string] $senderEmailAddress,
            [HashTable] $smtpSettings,
        [Parameter(Mandatory=$False, ParameterSetName = "System")]
        [Parameter(Mandatory=$False, ParameterSetName = "Organisation")]
            [string] $alertEmailTo,
            [string] $emailSubjectPrefix,
            [bool] $alertEmailToAllAdmins = $true
    )
    # First validate the SMTP Settings object
    if(!($smtpSettings.ContainsKey("smtpServerName") -and $smtpSettings.ContainsKey("smtpServerPort") -and $smtpSettings.ContainsKey("useAuthentication"))){
        throw "A valid smtpSettings object must be passed to the cmdlet which contains the mandatory parameters smtpServerName, smtpServerPort and useAuthentication."
    }
    # Determine if the System Scope or Organisation Scope is being set
    if($PSBoundParameters.ContainsKey('SystemScope')){
        # First retrieve the current configred policy
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.ServiceUri)admin/extension/settings/email"
            Method = "Get"
            APIVersion = 33
            APIType = "Legacy"
            LegacyAPIDataType = "JSON"
        }
        $EmailSettings = (Invoke-CICloudAPIRequest @RequestParameters).JSONData

        # Now set the parameters and send the update
        if($PSBoundParameters.ContainsKey('alertEmailTo')){
            $EmailSettings.alertEmailTo = $alertEmailTo
        }
        if($PSBoundParameters.ContainsKey('alertEmailToAllAdmins')){
            $EmailSettings.alertEmailToAllAdmins = $alertEmailToAllAdmins
        }
        if($PSBoundParameters.ContainsKey('emailSubjectPrefix')){
            $EmailSettings.emailSubjectPrefix = $emailSubjectPrefix
        }
        $EmailSettings.senderEmailAddress = $senderEmailAddress
        $EmailSettings.smtpSettings = $smtpSettings

        # Send the request to update the values
        $RequestParameters.Method = "PUT"
        $RequestParameters.Add("Data",(ConvertTo-JSON $EmailSettings -Depth 100))
        return (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    } else {
        # Check if the Org exists and get the Id
        try{
            $Org = Get-Org -Name $Organisation
        } catch {
            throw $_
        }
        # Retrieve the current configred policy
        [Hashtable] $RequestParameters = @{
            URI = "$($Org.Href)/settings/email"
            Method = "Get"
            APIVersion = 30
            APIType = "Legacy"
            LegacyAPIDataType = "XML"
        }
        $OrgPolicy = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        throw "Not implemented yet."
    }
}