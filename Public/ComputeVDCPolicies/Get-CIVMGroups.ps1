function Get-CIVMGroups(){
    <#
    .SYNOPSIS
    Get list of vCenter VM Groups registered against a Provider Virtual Datacenter (pVDC). These can be used for PVDC Compute Policy.

    .DESCRIPTION
    Get list of vCenter VM Groups registered against a Provider Virtual Datacenter (pVDC). These can be used for PVDC Compute Policy.

    This cmdlet has a known limitation that only the first 128 VM groups per PVDC are returned, I never expect to have more then 128 VM Groups in my installation so I have not enhanced this yet.

    .PARAMETER ProviderVDCName
    The Provider Virtual Datacenter (pVDC) Compute Policy Name to return VM Host Groups.

    .PARAMETER VMGroupName
    The VM Group Name to filter. If one does not exist nothing is returned.

    .EXAMPLE
    Get-CIVMGroups -ProviderVDCName "SiteA-PVDC-1"
    Returns a list of VM Groups for the Provider VDC named "SiteA-PVDC-1"

    .EXAMPLE
    Get-CIVMGroups -ProviderVDCName "SiteA-PVDC-1" -VMGroupName "US-West-AZ1"
    Returns the VM Group object for the VM Group named "US-West-AZ1" in the Provider VDC named "SiteA-PVDC-1" if it exists.

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-10
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()]  [string] $ProviderVDCName,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $VMGroupName
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Check if the Provider VDC exists and return the properties
    $ProviderVDC = Get-CIPVDC -Name $ProviderVDCName
    if($ProviderVDC.count -eq 0){
        throw "The Provider VDC with the name $ProviderVDCName does not exist or is not accessible. Please check the details and try again."
    }
    # Define the request "Body" with the filters or mandatory parameters
    [Hashtable] $APIParameters = @{
        type = "vmGroups"
        page = 1
        pageSize = 128
        format = "records"
        links = "true"
    }

    # Next define basic request properties for the API call - the filter has to be passed into the URI to work around Encoding issues with the API service
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.ServiceUri)query?filter=((clusterMoref==$($ProviderVDC.vcBackingClusterMoref));vcId==$($ProviderVDC.vimServer.id.Trim("urn:vcloud:vimserver:")))"
        Method = "Get"
        APIVersion = 33
        APIType = "Legacy"
        Data = $APIParameters
    }
    # Make the API call and return the result
    [xml] $Response = (Invoke-CICloudAPIRequest @RequestParameters).RawData

    # Create a Collection for the Results Objects
    $arrListVMGroups = New-Object -TypeName "System.Collections.ArrayList"

    if($PSBoundParameters.ContainsKey("VMGroupName")){
        [xml] $Response = $Response | Where-Object {$_.QueryResultRecords.VmGroupsRecord.vmGroupName -eq $VMGroupName}
    }

    foreach($vmGroup in $Response.QueryResultRecords.VmGroupsRecord){
        # Define the VMGroup object and add it to the collection to return
        [PSObject] $VMGroupObject = New-Object -TypeName PSObject -Property @{
            Type = "vmGroups"
            VMGroupName = $vmGroup.vmGroupName
            VMGroupId = "urn:vcloud:vmGroup:$($vmGroup.vmGroupId)"
            ProviderVDCId = $ProviderVDC.Id
            ProviderVDCName = $ProviderVDC.name
        }
        $arrListVMGroups.Add($VMGroupObject) | Out-Null
    }
    # Finally return the values
    $arrListVMGroups
}