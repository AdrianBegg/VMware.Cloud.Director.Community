function Remove-CIExternalNetworkSpecification(){
    <#
    .SYNOPSIS
    Removes an existing Network Specification from a Cloud Director External Network.

    .DESCRIPTION
    Removes an existing Network Specification from a Cloud Director External Network.

    .PARAMETER Name
    The Name for the External Network to remove the Subnet from.

    .PARAMETER Id
    The Id for the External Network to remove the Subnet from.

    .PARAMETER GatewayCIDR
    The Gateway CIDR (eg. 192.168.77.1/20 or 192.168.88.1/24)

    .PARAMETER Warn
    If $true will check during the operation if any addresses are currently assigned from the network.
    If $false if the Subnet has addresses in use it will attempt to remove the Subnet anyway.

    .EXAMPLE
    Remove-CIExternalNetworkSpecification -Id urn:vcloud:network:006a7fc5-5fcc-446a-a9bb-065a187f22c5 -GatewayCIDR 192.168.77.1/20
    Remove the Subnet with the Gateway 192.168.77.1 and a Prefix Length of 20 bits from the External Network with the Id urn:vcloud:network:006a7fc5-5fcc-446a-a9bb-065a187f22c5

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-02-18
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="ById")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
            [ValidateNotNullorEmpty()]  [string] $Name,
        [Parameter(Mandatory=$True, ParameterSetName="ById")]
            [ValidateNotNullorEmpty()]  [string] $Id,
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
        [Parameter(Mandatory=$True, ParameterSetName="ById")]
            [ValidateNotNullorEmpty()]  [string] $GatewayCIDR,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")]
        [Parameter(Mandatory=$False, ParameterSetName="ById")]
            [bool]$Warn = $true
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # First check if the External Network exists
    if($PSBoundParameters.ContainsKey("Name")){
        $NetworkSpecification = Get-CIExternalNetwork -Name $Name
    }
    if($PSBoundParameters.ContainsKey("Id")){
        $NetworkSpecification = Get-CIExternalNetwork -Id $Id
    }
    if($NetworkSpecification.Count -eq 0){
        throw "An External Network with the Id $Id could not be found. Please check the object and try again."
    }
    # Next check if the Gateway CIDR is value
    $GatewayIP = $GatewayCIDR.Split("/")[0]
    [int] $PrefixLength = $GatewayCIDR.Split("/")[1]
    try{
        [IPAddress]$GatewayIP | Out-Null
    } catch {
        throw "The provided Gateway address is not valid."
    }
    if($PrefixLength -notin 1..32){
        throw "The provided Gateway CIDR subnet prefix is not valid."
    }
    # Check if the subnet exists and is not in use
    $Subnet = $NetworkSpecification.subnets.values | Where-Object {($_.gateway -eq $GatewayIP) -and ($_.prefixLength -eq $PrefixLength)}
    if($Subnet.usedIpCount -ne 0){
        if($Warn){
            Write-Warning "There are currently allocated IPs in use for this subnet. If a new subnet does not exist with overlapping addressess space the update will fail. Ensure that all addresses are unallocated or a new subnet is already defined. Are you sure you wish to proceed?" -WarningAction Inquire
        }
    }
    if($Subnet.Count -eq 0){
        throw "A Subnet with the Gateway CIDR $GatewayCIDR does not exist on the External Network with the Id $($NetworkSpecification.id)."
    } else {
        # Update the specification with the object removed
        [PSObject[]] $UpdatedSubnets = ($NetworkSpecification.subnets.values | Where-Object {$_ -ne $Subnet})
        # Need to check if only one object will exist after the update
        if($UpdatedSubnets.Count -eq 1){
            $NetworkSpecification.subnets.values = @($UpdatedSubnets)
        } else {
            $NetworkSpecification.subnets.values = $UpdatedSubnets
        }

        # Next define basic request properties for the API call
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/externalNetworks/$($NetworkSpecification.id)"
            Method = "Put"
            APIVersion = 33
            Data = (ConvertTo-Json $NetworkSpecification -Depth 100)
        }
        # Make the API call and return the result
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        return $Response
    }
}