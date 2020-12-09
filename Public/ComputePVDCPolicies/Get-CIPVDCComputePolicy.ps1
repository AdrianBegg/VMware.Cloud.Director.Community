function Get-CIPVDCComputePolicy(){
    <#
    .SYNOPSIS
    Get list of Provider Virtual Datacenter (pVDC) compute policies.

    .DESCRIPTION
    Get list of Provider Virtual Datacenter (pVDC) compute policies.

    Only filtering by pvdc compute policy name is supported.

    .PARAMETER Name
    The Provider Virtual Datacenter (pVDC) Compute Policy Name to filter.

    .PARAMETER IncludeVMAssociations
    Wether to include associated VM objects with this Provider Virtual Datacenter (pVDC) Compute Policy in the results

    .EXAMPLE
    Get-CIPVDCComputePolicy
    Returns a collection of all Provider VDC Policies

    .EXAMPLE
    Get-CIPVDCComputePolicy -Name "Test-East" -IncludeVMAssociations
    Returns the Provider VDC Policy with the Name "Test-East" and includes VM Associations in the result

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-10
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
            [ValidateNotNullorEmpty()]  [string] $Name,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")]
            [switch] $IncludeVMAssociations
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
    if($PSBoundParameters.ContainsKey("Name")){
        $Filters.Add("name","==$Name")
    }
    if($Filters.Count -gt 0){
        $APIParameters.Add("filter",(Format-FIQL -Parameters $Filters))
    }

    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/pvdcComputePolicies"
        Method = "Get"
        APIVersion = 33
        Data = $APIParameters
    }
    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    $Results = $Response.values
    # Check there are more results then are in the current page continue to query until all items have been returned
    if($Response.pageCount -ne 0){
        while ($Response.pageCount -lt $Response.page){
            # Increment to the next page and add the results
            $APIParameters.page = ($APIParameters.page)++
            $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
            $Results += $Response.values
        }
    }
    # Check if the "-IncludeVMAssociations switch was provided"
    if($PSBoundParameters.ContainsKey("IncludeVMAssociations")){
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/pvdcComputePolicies/$($Results.id)/vms"
            Method = "Get"
            APIVersion = 33
        }
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        $Results | Add-Member Note* VMAssociations $Response.values
    }
    # Finally return the values
    $Results
}