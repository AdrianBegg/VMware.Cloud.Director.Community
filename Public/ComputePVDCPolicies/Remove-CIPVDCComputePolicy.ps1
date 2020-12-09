function Remove-CIPVDCComputePolicy(){
    <#
    .SYNOPSIS
    Removes a Provider Virtual Datacenter (pVDC) compute policies from the currently connected installation.

    .DESCRIPTION
    Removes a Provider Virtual Datacenter (pVDC) compute policies from the currently connected installation.

    .PARAMETER Name
    The Provider Virtual Datacenter (pVDC) Compute Policy Name to remove.

    .EXAMPLE
    Remove-CIPVDCComputePolicy -Name "Test-East"
    Removes the Provider Virtual Datacenter (pVDC) Compute Policy with the name "Test-East"

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-11
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()]  [string] $Name
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Check if the policy exists
    $ComputePVDCPolicy = Get-CIPVDCComputePolicy -Name $Name
    if($ComputePVDCPolicy.Count -eq 0){
        throw "A pVDC Compute Policy with the name $Name does not exist."
    }

    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/pvdcComputePolicies/$($ComputePVDCPolicy.id)"
        Method = "Delete"
        APIVersion = 33
    }
    # Make the API call and return the result
    (Invoke-CICloudAPIRequest @RequestParameters).JSONData | Out-Null
}