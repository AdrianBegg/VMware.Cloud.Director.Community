function New-CILogicalVMGroup(){
    <#
    .SYNOPSIS
    Creates a logical vm group in Cloud Director which can be used for VM Placement Policies

    .DESCRIPTION
    Creates a logical vm group in Cloud Director which can be used for VM Placement Policies

    .PARAMETER Name
    The Name of the Group in Cloud Director

    .PARAMETER Description
    A description for the group

    .PARAMETER ProviderVDCId
    The Provider VDC URN

    .PARAMETER VMGroupName
    The VM Group Name in the Provider VDC vCenter

    .EXAMPLE
    New-CILogicalVMGroup -Name "LG-Test-DC1" -Description "A Logical VM Group for DC-1" -ProviderVDCId "urn:vcloud:providervdc:f81715dd-d2b2-43e3-ba02-873a0dfa8c2f" -VMGroupName "Test-East"
    Creates a new Logical VM Group named "LG-Test-DC1" in Provider VDC "urn:vcloud:providervdc:f81715dd-d2b2-43e3-ba02-873a0dfa8c2f" using the VM Group Name "Test-East"

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-10
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateLength(1,128)]  [string] $Name,
            [ValidateLength(1,256)]  [string] $Description,
            [ValidateLength(1,256)]  [string] $ProviderVDCId,
            [string] $VMGroupName
    )
    # First check that the Provider VDC Id provided exists
    if((Get-CIPVDC -Id $ProviderVDCId).Count -eq 0){
        throw "A Provide VDC with the Id $ProviderVDCId could not be found. Please check the object and try again."
    }
    # Initalise an object for the VMGroup names and add it to a collection for correct object passing
    [PSObject] $VMGroupNameObj = New-Object -TypeName PSObject -Property @{
        name = $VMGroupName
    }
    # Create a Collection
    $arrListVMGroups = New-Object -TypeName "System.Collections.ArrayList"
    $arrListVMGroups.Add($VMGroupNameObj) | Out-Null

    # Define the Object to Post as Data to the API
    [PSObject] $Data = New-Object -TypeName PSObject -Property @{
        name = $Name
        description = $Description
        pvdcId = $ProviderVDCId
        namedVmGroupReferences = $arrListVMGroups
    }

    # Define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/logicalVmGroups"
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