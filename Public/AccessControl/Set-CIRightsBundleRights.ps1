function Set-CIRightsBundleRights(){
    <#
    .SYNOPSIS
    Adjusts (replaces) the Rights on an existing Cloud Director Rights Bundle to the collection of Rights provided.
    
    .DESCRIPTION
    Adjusts (replaces) the Rights on an existing Cloud Director Rights Bundle to the collection of Rights provided.
    
    .PARAMETER Name
    The Name of the Rights Bundle
    
    .PARAMETER Id
    The vCloud URN of the Rights Bundle
    
    .PARAMETER Rights
    A collection of Rights References e.g. [@{"name"="Organization vDC Gateway: Configure DNS","id"="urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7e7"}]
    
    .EXAMPLE
    Set-CIRightsBundleRights -Name "Default Rights Bundle" -Rights $colRights
    Sets the Default Rights Bundle rights to the rights defined in the collection $colRights
    
	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-05-13
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Id")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName = "ByName")]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$True, ParameterSetName = "ById")]
            [ValidateNotNullorEmpty()] [String] $Id,
        [Parameter(Mandatory=$True, ParameterSetName = "ById")]
        [Parameter(Mandatory=$True, ParameterSetName = "ByName")]
            [PSCustomObject[]] $Rights
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Check if the Rights Bundle exsits
    if($PSBoundParameters.ContainsKey('Id')){
        $RightsBundle = Get-CIRightsBundle -Id $Id
    } elseif($PSBoundParameters.ContainsKey('Name')){
        $RightsBundle = Get-CIRightsBundle -Name $Name
    }
    if($RightsBundle.Count -eq 0){
        throw "A rights bundle with the specified parameters can not be found. Please check the parameters and try again."
    }
    # Next construct a payload - stupid payload with page counts and sizes for some reason...weird API structure guys
    [Hashtable] $Payload = @{
        resultTotal = $Rights.Count
        pageCount = 1
        page = 1
        pageSize = $Rights.Count
        associations = $null
        values = $Rights
    }

    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/rightsBundles/$($RightsBundle.id)/rights"
        Method = "Put"
        APIVersion = 33
        Data = (ConvertTo-Json $Payload -Depth 100)
    }
    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    return $Response
}