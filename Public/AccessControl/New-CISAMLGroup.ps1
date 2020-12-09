
function New-CISAMLGroup(){
    <#
    .SYNOPSIS
    Adds a new SAML Group to the Cloud Director RBAC and assigns the group the provided Role

    .DESCRIPTION
    Adds a new SAML Group to the Cloud Director RBAC and assigns the group the provided Role

    .PARAMETER SystemScope
    Add to the RBAC of the System Scope

    .PARAMETER Organisation
    The Organisation Name

    .PARAMETER SAMLGroupName
    The SAML Group Name

    .PARAMETER RoleName
    The Cloud Director Role

    .EXAMPLE
    New-CISAMLGroup -SystemScope -SAMLGroupName "R-CD-Admins" -RoleName "System Administrators"
    Adds the SAML Group "R-CD-Admins" to the System Scope of the currently connected Cloud Director Service with the System Administrator role.

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2019-12-17
    VERSION: 1.0
    #>
    Param(
    [Parameter(Mandatory=$True, ParameterSetName = "System")]
        [switch] $SystemScope,
    [Parameter(Mandatory=$True, ParameterSetName = "Organisation")]
        [ValidateNotNullorEmpty()] [string] $Organisation,
    [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]  [string] $SAMLGroupName,
    [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]  [string] $RoleName


    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Define the request "Body" with the filters or mandatory parameters
    [Hashtable] $APIParameters = @{
        type = "role"
        page = 1
        pageSize = 128
        links = "true"
    }
    # Next define basic request properties for the API call - the filter has to be passed into the URI to work around Encoding issues with the API service
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.ServiceUri)query"
        Method = "Get"
        APIVersion = 32
        APIType = "Legacy"
        Data = $APIParameters
    }
    # Make the API call and return the result
    [xml] $Response = (Invoke-CICloudAPIRequest @RequestParameters).RawData
    # Check if the role exists
    $RoleObject = $Response.QueryResultRecords.RoleRecord | Where-Object {$_.name -eq $RoleName}
    if($RoleObject.count -ne 1){
        throw "Could not find a unique Role $RoleName in the currently connected Org. Please check and try again."
    }
    #Construct the Payload
    $Payload = "<root:Group xmlns:root=""http://www.vmware.com/vcloud/v1.5"" name=""$SAMLGroupName""><root:ProviderType>SAML</root:ProviderType><root:Role href=""$($RoleObject.href)"" type=""application/vnd.vmware.admin.role+xml""/></root:Group>"

    if($PSBoundParameters.ContainsKey('SystemScope')){
        # First retrieve the current configred policy
        $OrgURI = ($global:DefaultCIServers.ExtensionData.OrganizationReferences.OrganizationReference | Where-Object {$_.Name -eq "System"}).href
    } else {
        $OrgURI = ($global:DefaultCIServers.ExtensionData.OrganizationReferences.OrganizationReference | Where-Object {$_.Name -eq $Organisation}).href
    }
    # Check if the OrgURI is set
    if($OrgURI.Count -eq 0){
        throw "An Organisation with the provided name could not be found with the connected credentials. Please check the paramters and try again."
    }

    [Hashtable] $RequestParameters = @{
        URI = "$OrgURI/groups"
        Method = "Post"
        APIVersion = 33
        APIType = "Legacy"
        LegacyAPIDataType = "XML"
        Data = $Payload
    }
    # Make the API call to create the group
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).RawData
}