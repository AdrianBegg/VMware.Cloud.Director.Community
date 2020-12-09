function New-CIRole(){
     <#
    .SYNOPSIS
    Creates a new role on the currently connected Cloud Director Organisation.

    .DESCRIPTION
    Creates a new role on the currently connected Cloud Director Organisation.

    .PARAMETER Name
    The Role Name

    .PARAMETER Description
    The Role Description.

    .PARAMETER Rights
    A collection of Rights References e.g. [@{"name"="Organization vDC Gateway: Configure DNS","id"="urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7e7"}]

    .EXAMPLE
    New-CIRole -Name "Test Role" -Description "A Role for Testing with no rights"
    Creates a new Role with the Name "Test Role" and the description "A Role for Testing with no rights" with no rights assigned.

    .EXAMPLE
    New-CIRole -Name "Admin Group 2" -Description "A Role with only rights to Read the Admin API" -Rights [@{"name"="Organization: Perform Administrator Queries","id"="urn:vcloud:right:ddd7d2c5-9bec-3347-b848-70e7e8c65866"}]
    Creates a new Role with the Name "Test Role" and the description "A Role for Testing with no rights" with no rights assigned.

    AUTHOR: Adrian Begg
	LASTEDIT: 2020-06-01
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $Description,
        [Parameter(Mandatory=$False)]
            [PSCustomObject[]] $Rights
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Check if the role already exists
    $Role = Get-CIRolev2 -Name $Name
    if($Role.Count -ne 0){
        throw "A Role with the provided parameters already exists. Please check the provided parameters and try again."
    } else {
        # Create the payload for the POST
        [Hashtable] $Payload = @{
            id = $null
            name = $Name
            description = $Description
            bundleKey = "com.vmware.vcloud.undefined.key"
        }
        # Next define basic request properties for the API call
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/roles"
            Method = "Post"
            APIVersion = 34
            Data = (ConvertTo-Json $Payload -Depth 100)
        }
        # Make the API call and return the result
        try{
            $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
            #return $Response
        } catch {
            throw "An error occurred during API call."
        }
        # Next check if we should assign rights
        if($PSBoundParameters.ContainsKey('Rights')){
            $RoleObject = Set-CIRoleRights -Id $Response.id -Rights $Rights
        } else {
            $RoleObject = Get-CIRolev2 -Id $Response.id
        }
    }
    return $RoleObject
}