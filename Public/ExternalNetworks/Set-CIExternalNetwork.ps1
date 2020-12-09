function Set-CIExternalNetwork(){
    <#
    .SYNOPSIS
    Updates the basic parameters of a specific Cloud Director external network.

    .DESCRIPTION
    Updates the basic parameters of a specific  Cloud Director external network.

    To update the Subnets (Network Specifications) please use the Set-CIExternalNetworkSpecification, New-CIExternalNetworkSpecification or Remove-CIExternalNetworkSpecification cmdlets.

    .PARAMETER Id
    The Id for the External Network to update.

    .PARAMETER Name
    If provided the Name of the provided External Network will be updated to this value.

    .PARAMETER Description
    If provided the Description of the provided External Network will be updated to this value.

    .EXAMPLE
    Set-CIExternalNetwork -Id urn:vcloud:network:006a7fc5-5fcc-446a-a9bb-065a187f22c5 -Name "Ext-SDDC-01-T0" -Description "The External Network for the T0 Router attached to SDDC-01"
    Updates the Name and Description of the network with the Id urn:vcloud:network:006a7fc5-5fcc-446a-a9bb-065a187f22c5

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-02-18
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()]  [string] $Id,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $Name,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $Description
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # First check if the External Network exists
    $NetworkSpecification = Get-CIExternalNetwork -Id $Id
    if($NetworkSpecification.Count -eq 0){
        throw "An External Network with the Id $Id could not be found. Please check the object and try again."
    }
    # A variable to track if an update has occurred
    [bool] $UpdateRequired = $False

    # If Name or Description is provided update the specification
    if($PSBoundParameters.ContainsKey("Name")){
        $NetworkSpecification.Name = $Name
        $UpdateRequired = $true
    }
    if($PSBoundParameters.ContainsKey("Description")){
        $NetworkSpecification.Description = $Description
        $UpdateRequired = $true
    }
    # If an update is required make the API call otherwise do nothing
    if($UpdateRequired){
        # Next define basic request properties for the API call
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/externalNetworks/$Id"
            Method = "Put"
            APIVersion = 33
            Data = (ConvertTo-Json $NetworkSpecification -Depth 100)
        }
        # Make the API call and return the result
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        return $Response
    } else {
        Write-Warning "No changes were provided. No updates have occurred (nothing performed)."
    }
}