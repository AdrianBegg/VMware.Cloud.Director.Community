function New-CIExternalNetworkSpecification(){
    <#
    .SYNOPSIS
    Creates a new External Network Specification on a Cloud Director External Network

    .DESCRIPTION
    Creates a new External Network Specification on a Cloud Director External Network

    .PARAMETER Name
    The Name of the External Network

    .PARAMETER Id
    The External Network Id

    .PARAMETER Gateway
    The Gateway for the Network Specification

    .PARAMETER PrefixLength
    The CIDR Prefix Length for the network in bits

    .PARAMETER IPRanges
    The IP Range to be available in the Network Specification for customer usage

    .PARAMETER Enabled
    If the specification should be enabled for address distribution

    .PARAMETER dnsServer1
    Optionally the DNS server for the specification

    .PARAMETER dnsServer2
    Optionally the secondary DNS server for the specification

    .PARAMETER dnsSuffix
    Optionally the DNS suffix for the specification

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
            [ValidateNotNullorEmpty()]  [string] $Gateway,
            [ValidateRange(1,32)]  [int] $PrefixLength,
            [ValidateNotNullorEmpty()] [PSObject[]] $IPRanges,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")]
        [Parameter(Mandatory=$False, ParameterSetName="ById")]
            [bool] $Enabled = $true,
            [ValidateNotNullorEmpty()]  [string] $dnsServer1,
            [ValidateNotNullorEmpty()]  [string] $dnsServer2,
            [ValidateNotNullorEmpty()]  [string] $dnsSuffix
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Next check if the External Network exists
    if($PSBoundParameters.ContainsKey("Name")){
        $NetworkSpecification = Get-CIExternalNetwork -Name $Name
    }
    if($PSBoundParameters.ContainsKey("Id")){
        $NetworkSpecification = Get-CIExternalNetwork -Id $Id
    }
    if($NetworkSpecification.Count -eq 0){
        throw "An External Network with the Id $Id could not be found. Please check the object and try again."
    }
    # Check if the subnet exists with the same specification
    $Subnet = $NetworkSpecification.subnets.values | Where-Object {($_.gateway -eq $Gateway) -and ($_.prefixLength -eq $PrefixLength)}
    if($Subnet.Count -ne 0){
        throw "A Subnet with the Gateway $Gateway and the Subnet Prefix Length $PrefixLength already exists on the External Network with the Id $($NetworkSpecification.id). Please use Set-CIExternalNetworkSpecification to adjust an existing specification."
    } else {
        # Create a well formed object for the IP Ranges
        [PSObject] $IPRangesObject = @{
            values = $IPRanges
        }
        # Create a well formed object for the new Subnet to add to the specification
        [PSObject] $NewSubnet = @{
            gateway = $Gateway
            dnsServer1 = $dnsServer1
            dnsServer2 = $dnsServer2
            dnsSuffix = $dnsSuffix
            enabled = $Enabled
            ipRanges = $IPRangesObject
            prefixLength = $PrefixLength
            totalIpCount = 0
            usedIpCount = 0
        }
        # Update the specification object
        $NetworkSpecification.subnets.values += $NewSubnet

        # Next define basic request properties for the API call
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/externalNetworks/$($NetworkSpecification.Id)"
            Method = "Put"
            APIVersion = 33
            Data = (ConvertTo-Json $NetworkSpecification -Depth 100)
        }
        # Make the API call and return the result
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        return $Response
    }
}