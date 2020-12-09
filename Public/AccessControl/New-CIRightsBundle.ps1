function New-CIRightsBundle(){
    <#
    .SYNOPSIS
    Creates a new Rights Bundle in the currently connected Cloud Director instance.
    
    .DESCRIPTION
    Creates a new Rights Bundle in the currently connected Cloud Director instance.
    
    .PARAMETER Name
    The Name of the Rights Bundle
    
    .PARAMETER Description
    A description for the Rights Bundle
    
    .PARAMETER Rights
    A collection of Rights References e.g. [@{"name"="Organization vDC Gateway: Configure DNS","id"="urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7e7"}]
    
    .PARAMETER PublishToAllTenants
    If set will Publish the Rights Bundle to all tenants
    
    .EXAMPLE
    New-CIRightsBundle -Name "Test Bundle" -Description "Test Bundle1"
    Creates a new Rights Bundle with the Name "Test Bundle" and the Description "Test Bundle1" with no Rights assigned and not published to any tenants.

    .EXAMPLE
    New-CIRightsBundle -Name "Test Bundle" -Description "A Test Rights Bundle" -PublishToAllTenants
    Creates a new Rights Bundle with the Name "Test Bundle" and the Description "Test Bundle1" with no Rights assigned and published the bundle to all tenants.
    
    .EXAMPLE
    New-CIRightsBundle -Name "Test Bundle" -Description "A Test Rights Bundle" -PublishToAllTenants -Rights $colRights
    Creates a new Rights Bundle with the Name "Test Bundle" and the Description "Test Bundle1" and assigns the Rights in the collection $colRights and published the bundle to all tenants.

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-05-13
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $Description,
        [Parameter(Mandatory=$False)]
            [PSCustomObject[]] $Rights,
        [Parameter(Mandatory=$False)]
            [switch] $PublishToAllTenants
    )
    # Check if a Rights Bundle already exists with the same Name first
    $ExistingRightsBundle = Get-CIRightsBundle -Name $Name
    if($ExistingRightsBundle.Count -ne 0){
        throw "A rights bundle with the specified Name $Name already exists in this installation."
    }
    # Create the payload for the POST
    [Hashtable] $Payload = @{
        id = $null
        name = $Name
        description = $Description
    }
    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/rightsBundles"
        Method = "Post"
        APIVersion = 34
        Data = (ConvertTo-Json $Payload -Depth 100)
    }
    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    
    # Check if the Rights should be added
    if($PSBoundParameters.ContainsKey('Rights')){
        Set-CIRightsBundleRights -Id $Response.id -Rights $Rights | Out-Null
    }
    # Finally check if the PublishAll flag has been set
    # Should write a more robust cmdlet but don't need it at present - should consider writing as a function
    if($PSBoundParameters.ContainsKey('PublishToAllTenants')){
        # Next define basic request properties for the API call
        [Hashtable] $PublishAllRequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/rightsBundles/$($Response.id)/tenants/publishAll"
            Method = "Post"
            APIVersion = 34
        }
        $PublishAllResponse = (Invoke-CICloudAPIRequest @PublishAllRequestParameters).JSONData
    }
    # Get fresh data on the Rights Bundle and return to the caller
    return (Get-CIRightsBundle -Id $Response.id -IncludeRights)
}