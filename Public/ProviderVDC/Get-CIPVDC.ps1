function Get-CIPVDC(){
    <#
    .SYNOPSIS
    Get list of Provider Virtual Datacenter (pVDC).

    .DESCRIPTION
    Get list of Provider Virtual Datacenter (pVDC).

    .PARAMETER Name
    The Provider Virtual Datacenter (pVDC) Name to filter.

    .EXAMPLE
    Get-CIPVDC
    Returns a collection of all Provider VDCs defined in the installation

    .EXAMPLE
    Get-CIPVDC -Name "SiteA-PVDC3"
    Returns the Provider VDCs with the name "SiteA-PVDC3" if it exists in the installation otherwise returns $null

    .EXAMPLE
    Get-CIPVDC -Id "urn:vcloud:providervdc:f81715dd-d2b2-43e3-ba02-873a0dfa8c2f"
    Returns the Provider VDCs with the vCloud URN "urn:vcloud:providervdc:f81715dd-d2b2-43e3-ba02-873a0dfa8c2f" if it exists in the installation otherwise returns $null

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-10
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$False, ParameterSetName = "ByName")]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$False, ParameterSetName = "ById")]
            [ValidateNotNullorEmpty()] [String] $Id
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
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/providerVdcs"
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
    # Finally return the values based on any filters provided
    if($PSBoundParameters.ContainsKey('Name')){
        $Results = $Results | Where-Object{$_.name -eq $Name}
    } elseif ($PSBoundParameters.ContainsKey('Id')){
        $Results = $Results | Where-Object{$_.id -eq $Id}
    }
    # Need to make another call to the legacy API to get the Resource Pool backing the PVDC as this is not linked/available in the CloudAPI (and needed for VM Group Mapping)
    foreach($ProviderVDCRecord in $Results){
        # First define the request "Body" with any filters or mandatory parameters
        [Hashtable] $APIParameters = @{
            type = "resourcePool"
            page = 1
            pageSize = 128
            format = "records"
            links = "true"
        }
        # Next define basic request properties for the API call, legacy vCloud API does not allow Encoding so need to call the URI as a hot mess
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.ServiceUri)query?providerVdc==$($global:DefaultCIServers.ServiceUri)admin/providervdc/$($ProviderVDCRecord.id.Trim("urn:vcloud:providervdc:"))"
            Method = "Get"
            APIVersion = 33
            APIType = "Legacy"
            Data = $APIParameters
        }
        # Make the API call and return the result
        [xml] $Response = (Invoke-CICloudAPIRequest @RequestParameters).RawData
        $ProviderVDCRecord | Add-Member NoteProperty vcBackingClusterMoref ($Response.QueryResultRecords.ResourcePoolRecord.clusterMoref)
        $ProviderVDCRecord | Add-Member NoteProperty vcResourceGroupMoref ($Response.QueryResultRecords.ResourcePoolRecord.moref)
    }
    $Results
}