function Get-CIRightsCategory(){
    <#
    .SYNOPSIS
    Get a list of Cloud Director Rights Categories visible to the logged in user.

    .DESCRIPTION
    Get a list of Cloud Director Rights Categories visible to the logged in user.

    .PARAMETER Name
    Optionally the Name to filter the Rights Categories

    .PARAMETER Id
    Optionally the Id to filter the Rights Categories

    .PARAMETER TopLevelCatagoriesOnly
    If provided only the Parent Catagories (Top-Level) objects are returned

    .PARAMETER ExcludeTopLevelCatagories
    If provided the Parent Catagories (Top-Level) objects are excluded from the results

    .EXAMPLE
    Get-CIRightsCategory
    Returns a collection of all Rights Categories in the connected installation

    .EXAMPLE
    Get-CIRightsCategory -Id "urn:vcloud:rightsCategory:ee165a95-b115-325b-a2f3-1e6d1c5c1e7a"
    Returns the Right Category with the Id "urn:vcloud:rightsCategory:ee165a95-b115-325b-a2f3-1e6d1c5c1e7a" if it exists

    .EXAMPLE
    Get-CIRightsCategory -Name "Additional Services"
    Returns the Right Category with the name "Additional Services" if it exists

    .EXAMPLE
    Get-CIRightsCategory -ExcludeTopLevelCatagories
    Returns all of the Rights Categories but excludes the Top Level Rights Categories (which are assign no rights) from the results

    .EXAMPLE
    Get-CIRightsCategory -TopLevelCatagoriesOnly
    Returns a collection of the Top Level Rights Categories only

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
            [ValidateNotNullorEmpty()] [String] $Id,
        [Parameter(Mandatory=$False)]
            [switch] $TopLevelCatagoriesOnly,
            [switch] $ExcludeTopLevelCatagories
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
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/rightsCategories"
        Method = "Get"
        APIVersion = 33
        Data = $APIParameters
    }
    # Make the API call to retrieve all of the Rights
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    # Store the intermediate results
    $colRightsCategory = $Response.values
    # Check there are more results then are in the current page continue to query until all items have been returned
    if($Response.pageCount -ne 0){
        while ($Response.pageCount -gt $Response.page){
            # Increment to the next page and add the results
            ($APIParameters.page)++ | Out-Null
            $RequestParameters.Data = $APIParameters
            $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
            $colRightsCategory += $Response.values
        }
    }
    # Next we need to determine if we need to filter the results at all - to prevent multiple API calls process subset
    if($PSBoundParameters.ContainsKey('Name')){
        $colRightsCategoryResults = $colRightsCategory | Where-Object {$_.name -eq $Name}
    } elseif($PSBoundParameters.ContainsKey('Id')){
        $colRightsCategoryResults = $colRightsCategory | Where-Object {$_.id -eq $Id}
    } else {
        $colRightsCategoryResults = $colRightsCategory
    }
    # Next check filters for Top Level Catagories only or to exclude
    if($PSBoundParameters.ContainsKey('TopLevelCatagoriesOnly')){
        $colRightsCategoryResults = $colRightsCategoryResults | Where-Object {$_.subCategories.Count -ne 0}
    } elseif($PSBoundParameters.ContainsKey('ExcludeTopLevelCatagories')){
        $colRightsCategoryResults = $colRightsCategoryResults | Where-Object {$_.parent.Count -ne 0}
    }
    # Now for each Right Category that is a child add the parent name to make the results more senseful for processing
    foreach($objRightCategory in ($colRightsCategoryResults | Where-Object {$_.parent.Count -ne 0})){
        $objRightCategory | Add-Member Note* parentCategoryName (($colRightsCategory | Where-Object {$_.id -eq $objRightCategory.parent}).name)
    }
    return $colRightsCategoryResults
}
