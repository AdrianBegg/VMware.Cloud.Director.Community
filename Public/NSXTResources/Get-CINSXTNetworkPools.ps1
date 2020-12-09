
function Get-CINSXTNetworkPools(){
    <#
    .SYNOPSIS
    Returns the NSX Network Pools for the currently connected Cloud Director installation.

    .DESCRIPTION
    Returns the NSX Network Pools for the currently connected Cloud Director installation.

    .PARAMETER NSXTManagerName
    The NSX-T Manager name.

    .PARAMETER NetworkPoolName
    The Network Pool Name

    .EXAMPLE
    Get-CINSXTNetworkPools -NSXTManagerName "NSX-T-Manager"
    Returns all Network Pools for the NSX Manager named "NSX-T-Manager"

    .EXAMPLE
    Get-CINSXTNetworkPools -NSXTManagerName "NSX-T-Manager" -NetworkPoolName "Network-Pool ABC"
    Returns the Network Pool with the name "Network-Pool ABC" for the NSX Manager named "NSX-T-Manager"

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-17
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $NSXTManagerName,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $NetworkPoolName
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Check if the NSX-T Manager exists
    $NSXTManager = Get-CINSXTManager -Name $NSXTManagerName
    if($NSXTManager.Count -eq 0){
        throw "An NSX-T Manager with the provided name $NSXTManagerName does not exist in the currently connected installation."
    }

    # Query the installation for all NSX-T Managers
    [Hashtable] $NSXTRequestArgs = @{
        page = 1
        pageSize = 128
        links = "true"
    }
    # Filter has to go inline due to poor pharsing of the data
    [Hashtable] $NSXTRequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/networkPools/networkPoolSummaries?filter=(poolType==GENEVE;managingOwnerRef.id==$($NSXTManager.id))"
        Method = "Get"
        APIVersion = 33
        Data = $NSXTRequestArgs
    }
    $NetworkPools = ((Invoke-CICloudAPIRequest @NSXTRequestParameters).JSONData).values
    # Check if a filter was specified
    if($PSBoundParameters.ContainsKey('NetworkPoolName')){
        $NetworkPools = $NetworkPools | Where-Object{$_.name -eq $NetworkPoolName}
    }
    return $NetworkPools
}
