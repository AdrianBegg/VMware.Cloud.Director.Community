function Get-CIRolev2(){
    <#
    .SYNOPSIS
    Gets the Roles for the currently connected Cloud Director Organisation.

    .DESCRIPTION
    Gets the Roles for the currently connected Cloud Director Organisation. If connected under the System Organisation the System Roles will be returned. If connected as a Tenant the Tenant Scoped roles should be returned.

    .PARAMETER Name
    Optionally the Role Name. If no Role exists nothing is returned.

    .PARAMETER Id
    Optionally the Role Id. If no Role exists with this Id is returned.

    .EXAMPLE
    Get-CIRolev2
    Returns all of the Cloud Director Roles

    .EXAMPLE
    Get-CIRolev2 -Name "System Adminsitrator"
    Returns the Cloud Director role with the name "System Administrator"

    .EXAMPLE
    Get-CIRolev2 -Id urn:vcloud:role:67e119b7-083b-349e-8dfd-6cf0c19b83cf
    Returns the Cloud Director role with the Id "urn:vcloud:role:67e119b7-083b-349e-8dfd-6cf0c19b83cf"

    .EXAMPLE
    Get-CIRolev2 -Name "System Adminsitrator" -IncludeRights
    Returns the Cloud Director role with the name "System Administrator" including all rights.

    AUTHOR: Adrian Begg
	LASTEDIT: 2020-06-01
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$False, ParameterSetName = "ByName")]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$False, ParameterSetName = "ById")]
            [ValidateNotNullorEmpty()] [String[]] $Id,
        [Parameter(Mandatory=$False)]
            [switch] $IncludeRights
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Create the payload for the POST
    [Hashtable] $APIParameters = @{
        page = 1
        pageSize = 128
        links = $True
    }
    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/roles"
        Method = "Get"
        APIVersion = 34
        Data = (ConvertTo-Json $APIParameters -Depth 100)
    }
    if($PSBoundParameters.ContainsKey('Id')){
        # If Id was provided just execute and return the result
        $RequestParameters.URI += "/$Id"
        try{
            $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
            $colRoles = $Response
        } catch {
            $colRoles = $null
        }
    } else{
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        if($Response.values.Count -gt 0){
            # Store the intermediate results
            $colRoles = $Response.values
            # Check there are more results then are in the current page continue to query until all items have been returned
            if($Response.pageCount -ne 0){
                while ($Response.pageCount -gt $Response.page){
                    # Increment to the next page and add the results
                    ($APIParameters.page)++ | Out-Null
                    $RequestParameters.Data = $APIParameters
                    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
                    $colRoles += $Response.values
                }
            }
        }
    }
    # Filter the result if Name was provided
    if($PSBoundParameters.ContainsKey('Name')){
        $colRoles = ($colRoles | Where-Object {$_.name -eq $Name})
    }
    # Check if the Rights should be included
    if($colRoles.id -ne $null){
        if($PSBoundParameters.ContainsKey('IncludeRights')){
            foreach($objRoles in $colRoles){
                # First define the request "Body" with any filters or mandatory parameters
                [Hashtable] $RightsAPIParameters = @{
                    page = 1
                    pageSize = 128
                }
                # Next define basic request properties for the API call
                [Hashtable] $RightRequestParameters = @{
                    URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/roles/$($objRoles.id)/rights"
                    Method = "Get"
                    APIVersion = 34
                    Data = $RightsAPIParameters
                }
                # Make the API call to retrieve all of the Rights
                $RightsResponse = (Invoke-CICloudAPIRequest @RightRequestParameters).JSONData
                # Store the intermediate results
                $colRights = $RightsResponse.values
                # Check there are more results then are in the current page continue to query until all items have been returned
                if($RightsResponse.pageCount -ne 0){
                    while ($RightsResponse.pageCount -gt $RightsResponse.page){
                        # Increment to the next page and add the results
                        ($RightsAPIParameters.page)++ | Out-Null
                        $RightRequestParameters.Data = $RightsAPIParameters
                        $RightsResponse = (Invoke-CICloudAPIRequest @RightRequestParameters).JSONData
                        $colRights += $RightsResponse.values
                    }
                }
                # Add the rights to the RightsBundle object
                $objRoles | Add-Member Note* rights $colRights
            }
        }
    }
    return $colRoles
}