function Get-CIProviderVC(){
    <#
    .SYNOPSIS
    Returns a collection of eligble Provider vCenters that are registered and assosiated vCenter Resources

    .DESCRIPTION
    Returns a collection of eligble Provider vCenters that are registered and assosiated vCenter Resources

    KNOWN ISSUE : If a PVDC already exists for the CIProviderVC then the cmdlet fails - to be investigated after BETA

    .PARAMETER Name
    The Provider Virtual Center Name

    .EXAMPLE
    Get-CIProividerVC
    Returns all Provider vCenters registered against the connected Cloud Director Service

    .EXAMPLE
    Get-CIProividerVC -Name "Test-VC"
    Returns the Provider vCenters with the name Test-VC if it exists in the currently connected Cloud Director Service

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-17
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$False, ParameterSetName = "ByName")]
            [ValidateNotNullorEmpty()] [String] $Name
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Get the OrgId of the currently connected System Org
    $OrgHref = ($global:DefaultCIServers.ExtensionData.OrganizationReferences.OrganizationReference | Where-Object {$_.Name -eq "System"}).href
    [Hashtable] $OrgIdRequestParameters = @{
        URI = $OrgHref
        Method = "Get"
        APIVersion = 33
        APIType = "Legacy"
    }
    [xml] $OrgIdXML = (Invoke-CICloudAPIRequest @OrgIdRequestParameters).RawData
    $OrgId = ($OrgIdXML.AdminOrg.id).Trim("urn:vcloud:org:")

    # Define the request "Body" with the filters or mandatory parameters
    [Hashtable] $APIParameters = @{
        type = "virtualCenter"
        page = 1
        pageSize = 128
        links = "true"
        format = "records"
    }

    # Next define basic request properties for the API call, legacy vCloud API does not allow Encoding so need to call the "filter" in URI as a hot mess
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.ServiceUri)query?$filter=(id==$OrgId)"
        Method = "Get"
        APIVersion = 33
        APIType = "Legacy"
        Data = $APIParameters
    }
    # Make the API call to create the group
    [xml] $Response = (Invoke-CICloudAPIRequest @RequestParameters).RawData
    $colvCenters = ($Response.QueryResultRecords.VirtualCenterRecord)

    # Check if a filter was specified
    if($PSBoundParameters.ContainsKey('Name')){
        $colvCenters = $colvCenters | Where-Object{$_.name -eq $Name}
    }

    # Query the vCenter for available Resource Pools
    foreach($resvCenter in $colvCenters){
        # Return the resoruce pools and Storage Profiles
        $DRSClusterEndpoint = ($colvCenters.Link | Where-Object{$_.model -eq "ResourcePools"}).href
        $StorageProfileEndpoint = ($colvCenters.Link | Where-Object{$_.model -eq "StorageProfiles"}).href

        [Hashtable] $DRSClusterParameters = @{
            URI = $DRSClusterEndpoint
            Method = "Get"
            APIVersion = 33
        }
        $DRSClusters = ((Invoke-CICloudAPIRequest @DRSClusterParameters).JSONData).values
        # Now iterate over the clusters and retrieve
        foreach($Cluster in $DRSClusters){
            [Hashtable] $HardwareVersionParams = @{
                URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/virtualCenters/$($Cluster.vcId)/resourcePools/$($Cluster.moref)/hwv"
                Method = "Get"
                APIVersion = 33
            }
            # Return the Hardware Versions
            $SupportedHardwareVersions = ((Invoke-CICloudAPIRequest @HardwareVersionParams).JSONData).versions
            $Cluster | Add-Member NoteProperty SupportedHardwareVersions $SupportedHardwareVersions

            # Get the eligible Storage Profiles at a Cluster Level
            [Hashtable] $StorageProfileArgs = @{
                page = 1
                pageSize = 128
                links = "true"
                filter = "(_context==$($Cluster.moref))"
            }

            [Hashtable] $StorageProfileParams = @{
                URI = $StorageProfileEndpoint
                Method = "Get"
                APIVersion = 33
                Data = $StorageProfileArgs
            }
            $EligbleStorageProfiles = ((Invoke-CICloudAPIRequest @StorageProfileParams).JSONData).values
            $Cluster | Add-Member NoteProperty EligbleStorageProfiles $EligbleStorageProfiles

            # Get the Resource Pool Objects
            [Hashtable] $ResourcePoolArgs = @{
                page = 1
                pageSize = 128
                links = "true"
            }
            [Hashtable] $ResourcePoolParams = @{
                URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/virtualCenters/$($Cluster.vcId)/resourcePools/browse/$($Cluster.moref)"
                Method = "Get"
                APIVersion = 33
                Data = $ResourcePoolArgs
            }
            $ResourcePools = ((Invoke-CICloudAPIRequest @ResourcePoolParams).JSONData).values
            $Cluster | Add-Member NoteProperty ResourcePools $ResourcePools
        }
        # Add the DRS/HA Cluster and Resource Pools to the vCenter
        $resvCenter | Add-Member NoteProperty Clusters $DRSClusters
        # Add the vCenter Id - should fix this and use a call to the href but quick fix for now
        $resvCenter | Add-Member NoteProperty id $DRSClusters[0].vcId.Trim("urn:vcloud:vimserver:")
    }
    return $colvCenters
}