function New-CIPVDC(){
    <#
    .SYNOPSIS
    Creates a new Provider Virtual Datacenter (PVDC) in the currently connected Cloud Director.

    .DESCRIPTION
    Creates a new Provider Virtual Datacenter (PVDC) in the currently connected Cloud Director.

    .PARAMETER Name
    The PVDC Name

    .PARAMETER Description
    The Description for the Provider VDC

    .PARAMETER Enabled
    If the Provider VDC should be available for consumption

    .PARAMETER vCenterName
    The vCenter Name

    .PARAMETER ClusterName
    The HA/DRS Cluster Name

    .PARAMETER ResourcePoolName
    Optionally the Resource Pool

    .PARAMETER HardwareVersion
    The Hardware Version/Compatibility Level

    .PARAMETER StoragePolicies
    The Storage Policies to make available for consumption

    .PARAMETER NSXTManager
    The NSX-T Manager name

    .PARAMETER GeneveNetworkPool
    The Geneve backed Network Pool Name

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-12-20
	VERSION: 1.0
    #>

    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $Description,
        [Parameter(Mandatory=$False)]
            [bool] $Enabled=$true,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $vCenterName,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $ClusterName,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $ResourcePoolName,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [ValidateSet("vmx-07","vmx-08","vmx-09","vmx-10","vmx-11","vmx-12","vmx-13","vmx-14","vmx-15","vmx-17","vmx-18","vmx-19")] $HardwareVersion = "vmx-17",
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [string[]] $StoragePolicies,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [string] $NSXTManager,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [string] $GeneveNetworkPool
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # First check if the vCenter exists
    $ProviderVC = Get-CIProviderVC -Name $vCenterName
    if($ProviderVC.Count -eq 0){
        throw "A Provider vCenter with the name $vCenterName is not currently registered with the connected Cloud Director. Please check the name and try again."
    }
    # Next check the Cluster/Resource pool are eliglbe/exist, the Storage Policies are accessible and the Hardware Version is compatible
    $Cluster = $ProviderVC.Clusters | Where-Object {$_.name -eq $ClusterName}
    # Check if a resource pool was provided
    if($PSBoundParameters.ContainsKey('ResourcePoolName')){
        $ResourcePool = $Cluster.ResourcePools | Where-Object{$_.name -eq $ResourcePoolName}
    } else {
        $ResourcePool = $Cluster
    }
    # Check if the highest supported hardware version is supported
    if($HardwareVersion -notin  $Cluster.SupportedHardwareVersions){
        throw "The requested hardware version $HardwareVersion is not supported on the Cluster $ClusterName."
    }
    # Check if the Storage Policies are valid
    foreach($StorageProfile in $StoragePolicies){
        if($StorageProfile -notin ($ProviderVC.Clusters.EligbleStorageProfiles.name)){
            throw "The Storage Profile $StorageProfile is not an Eligble Storage Profile for cluster $ClusterName."
        }
    }

    # Get the NSX-T Manager
    $NSXTManagerObj = Get-CINSXTManager -Name $NSXTManager
    if($NSXTManagerObj.Count -eq 0){
        throw "A NSX-T Manager the name $NSXTManager is not currently registered with the connected Cloud Director. Please check the name and try again."
    }
    # Now get the Network Pool
    $NetworkPool = Get-CINSXTNetworkPools -NSXTManagerName $NSXTManager -NetworkPoolName $GeneveNetworkPool

    # Define the objects/structures to Post as Data to the API
    [PSObject] $nsxTNetworkPoolReference = New-Object -TypeName PSObject -Property @{
        href = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/networkPools/$($NetworkPool.id)"
        id = $NetworkPool.id
        name = $NetworkPool.Name
        type = $NetworkPool.poolType
    }
    [PSObject] $nsxTManagerReference = ($NSXTManagerObj | Select-Object id,name,href)

    # Objects for the vCenter and Resoruce Pool
    [PSObject] $vimServer = ($ProviderVC | Select-Object id,name,href,type)
    # Object needs to be in a collection for the post
    $vimCollection = New-Object -TypeName "System.Collections.ArrayList"
    $vimCollection.Add($vimServer) | Out-Null
    [PSObject] $vimObjectRef = New-Object -TypeName PSObject -Property @{
        moRef = $ResourcePool.moref
        vimServerRef = ($ProviderVC | Select-Object href,id)
        vimObjectType = "RESOURCE_POOL"
    }
    # Object needs to be in a collection for the post
    $vimObjectRefCol = New-Object -TypeName "System.Collections.ArrayList"
    $vimObjectRefCol.Add($vimObjectRef) | Out-Null
    # Object for the "Resoruce Pool Resoruces"
    $resourcePoolRefs = New-Object -TypeName PSObject -Property @{
        vimObjectRef = $vimObjectRefCol
    }

    # Create the Payload for the POST to create the Provider VDC
    [PSObject] $ProviderVDCParams = New-Object -TypeName PSObject -Property @{
        name = $Name
        description = $Description
        highestSupportedHardwareVersion = $HardwareVersion
        isEnabled = $Enabled
        vimServer = $vimCollection
        resourcePoolRefs = $resourcePoolRefs
        storageProfile = $StoragePolicies
        nsxTManagerReference = $nsxTManagerReference
        networkPool = $nsxTNetworkPoolReference
    }
    # Create the arguments for the post
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.ServiceUri)admin/extension/providervdcsparams"
        Method = "Post"
        APIVersion = 33
        APIType = "Legacy"
        LegacyAPIDataType = "JSON"
        Data = (ConvertTo-JSON $ProviderVDCParams -Depth 100)
    }
    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    return $Response
}
