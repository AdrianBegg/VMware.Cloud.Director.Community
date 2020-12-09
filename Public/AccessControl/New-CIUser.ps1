Function New-CIUser {
    <#
    .SYNOPSIS
    Creates a new local user in the connected vCloud Director instance.

    .DESCRIPTION
    Creates a new local user in the connected vCloud Director instance.

    .PARAMETER Username
    The login name of the new user

    .PARAMETER Password
    The password for the new user

    .PARAMETER FullName
    The full name of the new user

    .PARAMETER isEnabled
    If $true the user will be enabled

    .PARAMETER Org
    Optionally the Organisation to create the user.
    Default: System

    .PARAMETER Role
    The Role Name of the role to assign the new user

    .PARAMETER emailAddress
    Optionally the email address of the new user

    .PARAMETER telephone
    Optionally the Telephone Number for the new user

    .PARAMETER im
    Optionally The Instant Messaging Id of the new user

    .PARAMETER storedVmQuota
    The Stored VM Quota for the User. 0 = Unlimmited

    .PARAMETER deployedVmQuota
    The Deployed VM Quota for the User. 0 = Unlimmited

    .EXAMPLE
    An example

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-04-08
    VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $Username,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String]$Password,
        [Parameter(Mandatory=$True)]
            [bool]$isEnabled,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $Org = "System",
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $Role,
        [Parameter(Mandatory=$False)]
            [String] $FullName = $null,
        [Parameter(Mandatory=$False)]
            [String] $emailAddress = $null,
        [Parameter(Mandatory=$False)]
            [String] $telephone = $null,
        [Parameter(Mandatory=$False)]
            [String] $im = $null,
        [Parameter(Mandatory=$False)]
            [int] $storedVmQuota = 0,
        [Parameter(Mandatory=$False)]
            [int] $deployedVmQuota = 0
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Next check if the Organisation exists
    [string] $OrganisationURI = ($global:DefaultCIServers.ExtensionData.OrganizationReferences.OrganizationReference | Where-Object {$_.Name -eq $Org}).Href
    if($OrganisationURI.Count -eq 0){
        throw "An Organisation with the provided name could not be found with the connected credentials. Please check the paramters and try again."
    }
    # TO DO: Need better logic here - this only works for the Scope of the users connected Org; needs to be able to administratively set from the System Scope other Orgs (not high prio)
    # Next check if the role exists for the connected organisation
    # Also need to change the case of the roles; the property names in PowerCLI will cause an exception to be thrown
    $RoleReference = ($global:DefaultCIServers.ExtensionData.RoleReferences.RoleReference | Where-Object {$_.Name -eq $Role}) | Select-Object @{N=’vCloudExtension’; E={$_.VCloudExtension}},@{N=’href’; E={$_.Href}},@{N=’type’; E={$_.Type}},link
    if($RoleReference.Count -eq 0){
        throw "A role with the name $Role can not be found in the currently connected Organisation $Org. Please check the paramters and try again."
    }
    # Create the Payload object for the POST to create the New user
    [PSObject] $objUser = New-Object -TypeName PSObject -Property @{
        name = $Username
        fullName = $FullName
        password = $Password
        isEnabled = $isEnabled
        isGroupRole = $null
        emailAddress = $emailAddress
        telephone = $telephone
        im = $im
        role = $RoleReference
        storedVmQuota = $storedVmQuota
        deployedVmQuota = $deployedVmQuota
    }
    # Define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$OrganisationURI/users"
        Method = "Post"
        APIVersion = 33
        APIType = "Legacy"
        LegacyAPIDataType = "JSON"
        Data = (ConvertTo-JSON $objUser -Depth 100)
    }
    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters)
    $Results = $Response.JSONData
    return $Results
}