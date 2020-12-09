function New-CIPVDCComputePolicy(){
    <#
    .SYNOPSIS
    Creates a new VM Placement Policy (VDC Compute Policy) on a Provider VDC.

    .DESCRIPTION
    A Placement Policy can be used to guarantee or set prefered placement of workloads on designated host groups within the Provider VDC.

    Some example usage for Placement Policies is to ensure that workloads run only on properly licensed hosts. Another use case is for Fault Domains within a single Provider VDC (e.g. Org VDCs deployed across a Stretch Cluster)

    .PARAMETER Name
    The Name of the PVDC Compute Policy

    .PARAMETER Description
    A description of what the PVDC Compute Policy is used for

    .PARAMETER ProviderVDCName
    The Provider VDC Name to associate the policy with

    .PARAMETER VMGroupName
    The VM Group Name in vCenter to map. The VM Group must already exist and be assosiated with the Cluster backing the Provider VDC

    .EXAMPLE
    New-CIPVDCComputePolicy -Name "East" -Description "A PVDC Compute Profile for US-East-1" -ProviderVDCName "SiteA-PVDC-1" -VMGroupName "US-East"
    Creates a new Provider VDC Compute Policy named "East" which maps to VM Group Named "US-East" and associates it with the Provider VDC "SiteA-PVDC-1"

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-10
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateLength(1,128)]  [string] $Name,
            [ValidateLength(1,256)]  [string] $Description,
            [ValidateLength(1,256)]  [string] $ProviderVDCName,
            [string] $VMGroupName
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # First check that the Provider VDC provided exists
    if((Get-CIPVDC -Name $ProviderVDCName).Count -eq 0){
        throw "A Provide VDC with the Name $ProviderVDCName could not be found. Please check the object and try again."
    }
    # Next retrieve the vmGroup object and check if it exists
    $objVMGroup = Get-CIVMGroups -ProviderVDCName $ProviderVDCName -VMGroupName $VMGroupName
    if($objVMGroup.Count -eq 0){
        throw "A VM Host Group with the Name $VMGroupName can not be found configured on Provider VDC $ProviderVDCName. Please check and try again."
    }

    # Initalise an object for the VMGroup names and add it to a collection for correct object passing
    [PSObject] $VMGroupNameObj = New-Object -TypeName PSObject -Property @{
        name = $objVMGroup.VMGroupName
        id = $objVMGroup.VMGroupId
    }
    # Array of array's for unknown reasons
    $arrListVMGroups = New-Object -TypeName "System.Collections.ArrayList"
    $arrListVMGroups.Add($VMGroupNameObj) | Out-Null
    $arrListVMGroupsCollection = New-Object -TypeName "System.Collections.ArrayList"
    $arrListVMGroupsCollection.Add($arrListVMGroups) | Out-Null

    # Define the Object to Post as Data to the API
    [PSObject] $Data = New-Object -TypeName PSObject -Property @{
        name = $Name
        description = $Description
        pvdcId = $objVMGroup.ProviderVDCId
        namedVmGroups = $arrListVMGroupsCollection
    }

    # Define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/pvdcComputePolicies"
        Method = "Post"
        APIVersion = 33
        Data = (ConvertTo-JSON $Data -Depth 100)
    }
    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters)
    $Results = $Response.JSONData

    # Finally return the values
    $Results
}