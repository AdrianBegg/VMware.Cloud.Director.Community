function Set-CIRoleRights(){
    <#
    .SYNOPSIS
    Adjusts (replaces) the Rights on an existing Cloud Director Role to the collection of Rights provided.

    .DESCRIPTION
    Adjusts (replaces) the Rights on an existing Cloud Director Role to the collection of Rights provided.

    .PARAMETER Name
    The Name of the Role

    .PARAMETER Id
    The vCloud URN of the Role

    .PARAMETER Rights
    A collection of Rights References e.g. [@{"name"="Organization vDC Gateway: Configure DNS","id"="urn:vcloud:right:d85b0e92-b9e8-31af-9b19-23cd00cae7e7"}]

    AUTHOR: Adrian Begg
	LASTEDIT: 2020-06-01
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

    # Check if the Role exsits
    if($PSBoundParameters.ContainsKey('Id')){
        $Role = Get-CIRole -Id $Id
    } elseif($PSBoundParameters.ContainsKey('Name')){
        $Role = Get-CIRole -Name $Name
    }
    if($Role.Count -eq 0){
        throw "A Role with the provided parameters does not exist. Please check the provided parameters and try again."
    } else {
        # Next construct a payload - stupid payload with page counts and sizes for some reason...weird API structure guys
        [Hashtable] $Payload = @{
            values = $Rights
        }
        # Next define basic request properties for the API call
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/roles/$($Role.id)/rights"
            Method = "Put"
            APIVersion = 33
            Data = (ConvertTo-Json $Payload -Depth 100)
        }
        # Make the API call and return the result
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        return (Get-CIRole -Id $Role.id -IncludeRights)
    }
}