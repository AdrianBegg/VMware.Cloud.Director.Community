function Set-CIPasswordPolicy(){
    <#
    .SYNOPSIS
    Adjusts the Local Account Password Policy for Cloud Director Service

    .DESCRIPTION
    Adjusts the Local Account Password Policy for Cloud Director Service

    .PARAMETER SystemScope
    If provided sets the default system policy

    .PARAMETER adminAccountLockoutEnabled
    If $True the System Administrator account can be locked out

    .PARAMETER Organisation
    The Organisation to apply the policy

    .PARAMETER accountLockoutEnabled
    If $True the policy will be enabled and accounts can be locked out

    .PARAMETER invalidLoginsBeforeLockout
    The number of attempts allowed before the account is locked out

    .PARAMETER accountLockoutIntervalMinutes
    The interval in minutes before a locked account is unlocked.

    .EXAMPLE
    Set-CIPasswordPolicy -SystemScope -adminAccountLockoutEnabled $False -accountLockoutEnabled $True -accountLockoutIntervalMinutes 30 -invalidLoginsBeforeLockout 5
    Sets a system level policy to enable lockout after 5 failed attempts for 30 minutes. System Administrators can not be locked out.

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-01-14
    VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True, ParameterSetName = "System")]
            [switch] $SystemScope,
        [Parameter(Mandatory=$False, ParameterSetName = "System")]
            [ValidateNotNullorEmpty()]  [bool] $adminAccountLockoutEnabled,
        [Parameter(Mandatory=$True, ParameterSetName = "Organisation")]
            [ValidateNotNullorEmpty()] [string] $Organisation,
        [Parameter(Mandatory=$False, ParameterSetName = "System")]
        [Parameter(Mandatory=$False, ParameterSetName = "Organisation")]
            [ValidateNotNullorEmpty()] [bool] $accountLockoutEnabled = $true,
            [ValidateRange(1, [int]::MaxValue)] [int] $invalidLoginsBeforeLockout = 5,
            [ValidateRange(1, [int]::MaxValue)] [int] $accountLockoutIntervalMinutes = 10
    )
    # Determine if the System Scope or Organisation Scope is being set
    if($PSBoundParameters.ContainsKey('SystemScope')){
        # First retrieve the current configred policy
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.ServiceUri)admin/extension/settings/passwordPolicy"
            Method = "Get"
            APIVersion = 33
            APIType = "Legacy"
            LegacyAPIDataType = "JSON"
        }
        $PasswordPolicy = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        # Now set the parameters and send the update
        if($PSBoundParameters.ContainsKey('adminAccountLockoutEnabled')){
            $PasswordPolicy.adminAccountLockoutEnabled = $adminAccountLockoutEnabled
        }
        if($PSBoundParameters.ContainsKey('accountLockoutEnabled')){
            $PasswordPolicy.accountLockoutEnabled = $accountLockoutEnabled
        }
        if($PSBoundParameters.ContainsKey('invalidLoginsBeforeLockout')){
            $PasswordPolicy.invalidLoginsBeforeLockout = $invalidLoginsBeforeLockout
        }
        if($PSBoundParameters.ContainsKey('accountLockoutIntervalMinutes')){
            $PasswordPolicy.accountLockoutIntervalMinutes = $accountLockoutIntervalMinutes
        }
        # Send the request to update the values
        $RequestParameters.Method = "PUT"
        $RequestParameters.Add("Data",(ConvertTo-JSON $PasswordPolicy -Depth 100))
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
            URI = "$($Org.Href)/settings"
            Method = "Get"
            APIVersion = 33
            APIType = "Legacy"
            LegacyAPIDataType = "JSON"
        }
        $OrgPolicy = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        # Now set the parameters and send the update
        if($PSBoundParameters.ContainsKey('accountLockoutEnabled')){
            $OrgPolicy.orgPasswordPolicySettings.accountLockoutEnabled = $accountLockoutEnabled
        }
        if($PSBoundParameters.ContainsKey('invalidLoginsBeforeLockout')){
            $OrgPolicy.orgPasswordPolicySettings.invalidLoginsBeforeLockout = $invalidLoginsBeforeLockout
        }
        if($PSBoundParameters.ContainsKey('accountLockoutIntervalMinutes')){
            $OrgPolicy.orgPasswordPolicySettings.accountLockoutIntervalMinutes = $accountLockoutIntervalMinutes
        }
        # Send the request to update the values
        $RequestParameters.Method = "PUT"
        $RequestParameters.Add("Data",(ConvertTo-JSON $OrgPolicy -Depth 100))
        return (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    }
}