function Get-CIExternalNetwork(){
    <#
    .SYNOPSIS
    Returns the Cloud Director External Networks.
    
    .DESCRIPTION
    Returns the Cloud Director External Networks. If a filter is provided and no External Networks exist that match the specification nothing is returned.
    
    .PARAMETER Name
    The External Network name
    
    .PARAMETER Id
    The External Network Id (URN)
    
    .PARAMETER ProviderVDCId
    The Provider VDC Id (URN)
    
    .EXAMPLE
    Get-CIExternalNetwork
    Returns a collection of all Cloud Director External Networks
    
    .EXAMPLE
    Get-CIExternalNetwork -Name "External Network ABC"
    Returns the Cloud Director External Network with the name "External Network ABC" if it exists 

    .EXAMPLE
    Get-CIExternalNetwork -Id urn:vcloud:network:006a7fc5-5fcc-446a-a9bb-065a187f22c5
    Retruns the Cloud Director External Network with the Id urn:vcloud:network:006a7fc5-5fcc-446a-a9bb-065a187f22c5 if it exists

    .EXAMPLE
    Get-CIExternalNetwork -ProviderVDCId urn:vcloud:providervdc:8b6d1c08-7001-4a03-ba60-dade2cf010c8
    Returns the Cloud Director External Network assosiated with the Provider VDC with the Id urn:vcloud:providervdc:8b6d1c08-7001-4a03-ba60-dade2cf010c8

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-02-18
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
            [ValidateNotNullorEmpty()]  [string] $Name,
        [Parameter(Mandatory=$True, ParameterSetName="ById")]
            [ValidateNotNullorEmpty()]  [string] $Id,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")]
        [Parameter(Mandatory=$True, ParameterSetName="ByProviderVDC")]
            [ValidateNotNullorEmpty()]  [string] $ProviderVDCId
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # First define the request "Body" with any filters or mandatory parameters
    [Hashtable] $APIParameters = @{
        page = 1
        pageSize = 128
    }
    # Create a Hashtable for FIQL filters
    [Hashtable] $Filters = @{}
    # If Name is provided add to the FIQL filter
    if($PSBoundParameters.ContainsKey("Name")){
        $Filters.Add("name","==$Name")
    }
    if($PSBoundParameters.ContainsKey("Id")){
        $Filters.Add("id","==$Id")
    }
    if($PSBoundParameters.ContainsKey("ProviderVDCId")){
        $Filters.Add("_context","==$ProviderVDCId")
    }
    if($Filters.Count -gt 0){
        $APIParameters.Add("filter",(Format-FIQL -Parameters $Filters))
    }
    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/externalNetworks"
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