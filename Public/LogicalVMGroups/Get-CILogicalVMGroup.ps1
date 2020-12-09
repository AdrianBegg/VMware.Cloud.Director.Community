function Get-CILogicalVMGroup(){
    <#
    .SYNOPSIS
    Get list of logical vm groups.

    .DESCRIPTION
    Get list of logical vm groups.

    .PARAMETER Name
    The Provider Virtual Datacenter (pVDC) Compute Policy Name to filter.

    .EXAMPLE
    Get-CILogicalVMGroup
    Returns a list of all Logical Groups

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-10
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $Name
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # First define the request "Body" with any filters or mandatory parameters
    [Hashtable] $APIParameters = @{
        page = 1
        pageSize = 128
    }
    if($PSBoundParameters.ContainsKey('Name')){
        $APIParameters.Add("filter","name==$Name*")
    }

    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/logicalVmGroups"
        Method = "Get"
        APIVersion = 33
        Data = $APIParameters
    }
    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    $Results = $Response.values
    # Check there are more results then are in the current page continue to query until all items have been returned
    if($Response.pageCount -ne 0){
        while ($Response.pageCount -gt $Response.page){
            # Increment to the next page and add the results
            ($APIParameters.page)++ | Out-Null
            $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
            $Results += $Response.values
        }
    }
    # Finally return the values
    $Results
}