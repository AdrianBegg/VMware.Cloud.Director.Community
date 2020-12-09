function Get-CIVDCComputePolicy(){
    <#
    .SYNOPSIS
    Get list of Organization vDC (OrgVDC) Compute policies.

    .DESCRIPTION
    Get list of Organization vDC (OrgVDC) Compute policies.

    The objects can be filtered by type (VM Placement Policy or VM Sizing Policy), Name or filtered by the OrgVDC that they are assosiated with.

    .PARAMETER Name
    Optionally the Organization vDC (OrgVDC) Compute Policy Name to return.

    .PARAMETER IncludeVMAssociations
    Includes VM Associations with the Compute Policy in the result.

    .PARAMETER IncludeOrgVDCAssociations
    Includes the OrgVDC Associations with the Compute Policy in the result.

    .PARAMETER OrgVDCURNId
    An OrgVDC URN Id
    If provided results will be filtered by the Compute VDC Policies assosiated with the provided OrgVDC.

    .PARAMETER SizingPolicyOnly
    If set only VM Sizing Policies are returned

    .PARAMETER PlacementPolicyOnly
    If set only VM Placement Policies are returned

    .EXAMPLE
    Get-CIVDCComputePolicy -Name "Example" -IncludeOrgVDCAssociations
    Returns the Org VDC Compute Policy with the Name "Example" and includes the Org VDCs that have this policy available.

    .EXAMPLE
    Get-CIVDCComputePolicy -OrgVDCURNId (Get-OrgVdc -Name "TestVDC" -Org "TestOrg").id
    Returns the Org VDC Compute Policy assosiated with the OrgVDC "TestVDC" in Org "TestOrg"

    .EXAMPLE
    Get-CIVDCComputePolicy -OrgVDCURNId (Get-OrgVdc -Name "TestVDC" -Org "TestOrg").id -PlacementPolicyOnly
    Returns the VM Placement Policies (Org VDC Compute Policy) assosiated with the OrgVDC "TestVDC" in Org "TestOrg"

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-11
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
            [ValidateNotNullorEmpty()]  [string] $Name,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")]
            [switch] $IncludeVMAssociations,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")]
            [switch] $IncludeOrgVDCAssociations,
        [Parameter(Mandatory=$False, ParameterSetName="ByOrgVDC")]
            [string] $OrgVDCURNId,
        [Parameter(Mandatory=$False)]
            [switch] $SizingPolicyOnly,
            [switch] $PlacementPolicyOnly
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
    if($PSBoundParameters.ContainsKey("SizingPolicyOnly")){
        $Filters.Add("isSizingOnly","==true")
    }
    if($PSBoundParameters.ContainsKey("PlacementPolicyOnly")){
        $Filters.Add("isSizingOnly","==false")
    }
    if($PSBoundParameters.ContainsKey("OrgVDCURNId")){
        $Filters.Add("_context","==$OrgVDCURNId")
    }
    if($Filters.Count -gt 0){
        $APIParameters.Add("filter",(Format-FIQL -Parameters $Filters))
    }

    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/vdcComputePolicies"
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
    # Check if the "-IncludeVMAssociations switch was provided"
    if($PSBoundParameters.ContainsKey("IncludeVMAssociations")){
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/vdcComputePolicies/$($Results.id)/vms"
            Method = "Get"
            APIVersion = 33
        }
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        $Results | Add-Member Note* VMAssociations $Response.values
    }
    # Check if the "-IncludeOrgVDCAssociations switch was provided"
    if($PSBoundParameters.ContainsKey("IncludeOrgVDCAssociations")){
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/vdcComputePolicies/$($Results.id)/vdcs"
            Method = "Get"
            APIVersion = 33
        }
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        $Results | Add-Member Note* VDCAssociations $Response
    }
    # Finally return the values
    $Results
}