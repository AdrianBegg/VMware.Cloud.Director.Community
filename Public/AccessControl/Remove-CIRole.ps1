function Remove-CIRole(){
    <#
    .SYNOPSIS
    Removes a Role from the currently connected Cloud Director Organisation.

    .DESCRIPTION
    Removes a Role from the currently connected Cloud Director Organisation. If connected under the System Organisation the System Roles will be the cmdlet scope. If connected as a Tenant the Tenant Scoped roles will be removed.

    .PARAMETER Name
    The Role Name

    .PARAMETER Id
    The Role Id

    .EXAMPLE
    Remove-CIRole -Name "Test"
    Removes the Cloud Director role with the name Test

    .EXAMPLE
    Remove-CIRole -Id "urn:vcloud:role:d19e98ed-ff6d-4b68-9179-e3822efb3981"
    Removes the Cloud Director role with the Id "urn:vcloud:role:d19e98ed-ff6d-4b68-9179-e3822efb3981"

    AUTHOR: Adrian Begg
	LASTEDIT: 2020-06-01
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="ById")]
    Param(
        [Parameter(Mandatory=$False, ParameterSetName = "ByName")]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$False, ParameterSetName = "ById")]
            [ValidateNotNullorEmpty()] [String[]] $Id
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Check if the Role exists
    if($PSBoundParameters.ContainsKey('Name')){
        $Role = Get-CIRolev2 -Name $Name
    } elseif($PSBoundParameters.ContainsKey('Id')){
        $Role = Get-CIRolev2 -Id $Id
    }
    if($Role.Count -eq 0){
        throw "A Role with the provided parameters does not exist. Please check the provided parameters and try again."
    } else {
        # Next define basic request properties for the API call
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/roles/$($Role.id)"
            Method = "Delete"
            APIVersion = 34
            Data = (ConvertTo-Json $APIParameters -Depth 100)
        }
        try{
            $Response = (Invoke-CICloudAPIRequest @RequestParameters)
        } catch {
            throw "An error occurred during the call to remove the Role."
        }
    }
}