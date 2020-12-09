function Get-CIRights(){
    <#
    .SYNOPSIS
    Get a list of Cloud Director Rights visible to the logged in user.

    .DESCRIPTION
    Get a list of Cloud Director Rights visible to the logged in user.

    .PARAMETER Name
    Optionally a Right Name to filter results

    .PARAMETER Id
    Optionally a collection of Right Id to filter results

    .EXAMPLE
    Get-CIRights
    Returns a collection of all Rights on the currently connected Cloud Director that are visable to the logged in user.

    .EXAMPLE
    Get-CIRights -Name "Organization: Edit Name"
    Returns the Right with the name "Organization: Edit Name" on connected Cloud Director if it exists/the user has rights to see it.

    .EXAMPLE
    Get-CIRights -Id urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7e7
    Returns the Right with the Id "urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7e7" on connected Cloud Director if it exists/the user has rights to see it.

    .EXAMPLE
    Get-CIRights -Id @("urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7e7","urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7a3")
    Returns the rights with the Id's "urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7e7" and "urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7a3" on connected Cloud Director if it exists/the user has rights to see it.

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-01-08
	VERSION: 1.0
    #>

    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$False, ParameterSetName = "ByName")]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$False, ParameterSetName = "ById")]
            [ValidateNotNullorEmpty()] [String[]] $Id
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # First define the request "Body" with any filters or mandatory parameters
    [Hashtable] $APIParameters = @{
        page = 1
        pageSize = 128
    }
    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/rights"
        Method = "Get"
        APIVersion = 33
        Data = $APIParameters
    }
    # Create a Hashtable for FIQL filters
    [Hashtable] $Filters = @{}
    # If Name is provided add to the FIQL filter
    if($PSBoundParameters.ContainsKey("Name")){
        $Filters.Add("name","==$Name")
    }
    if($Filters.Count -gt 0){
        $APIParameters.Add("filter",(Format-FIQL -Parameters $Filters))
    }

    # Check if a Id filter was specified
    if($PSBoundParameters.ContainsKey("Id")){
        # If an Id (or multiple Id's) are provided, need to create a collection for each Right
        foreach($RightId in $Id){
            $RequestParameters.URI += "/$RightId"
            $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
            $colRights += $Response
        }
    } else {
        # Make the API call to retrieve the Rights
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        # Store the intermediate results
        $colRights = $Response.values
        # Check there are more results then are in the current page continue to query until all items have been returned
        if($Response.pageCount -ne 0){
            while ($Response.pageCount -gt $Response.page){
                # Increment to the next page and add the results
                ($APIParameters.page)++ | Out-Null
                $RequestParameters.Data = $APIParameters
                $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
                $colRights += $Response.values
            }
        }
    }

    # Check if something was returned
    if($colRights.Count -gt 0){
        # Next for each Right get the Right Catagory
        # This approach is not the most efficent (it generates alots of API calls from the Get-CIRightsCategory cmdlet)
        foreach($objRight in $colRights){
            # Query the Right Catagory and retireve the Parent
            $RightCategory = Get-CIRightsCategory -Id $objRight.category
            $objRight | Add-Member Note* categoryName $RightCategory.name
            $objRight | Add-Member Note* parentCategoryName $RightCategory.parentCategoryName
        }
    }
    # Return the Rights
    return $colRights
}