function New-CIVMSizingPolicy(){
    <#
    .SYNOPSIS
    Creates a new Organisation Virtual Datacenter Compute Policy for Sizing (VM Sizing Policy).

    .DESCRIPTION
    This cmdlet creates a new Organisation Virtual Datacenter Compute Policy for VM Sizing (VM Sizing Policy).

    If only the Name property is provided the resulting policy will allow a customer to set any configuration supported by the installation.

    If a value is provide for other properties (e.g. cpuSpeed) it will take presidence over a Org VDC level default/be enforced for the VM.

    .PARAMETER Name
    The Name of the VM Sizing Policy

    .PARAMETER Description
    A description that will be displayed to users describing the VM Sizing Policy

    .PARAMETER cpuSpeed
    The cpuSpeed in Mhz for the VM

    .PARAMETER cpuCount
    The vCPU Count for the VM

    .PARAMETER coresPerSocket
    The number of Cores to present to the VM per Socket

    .PARAMETER cpuReservationGuarantee
    The Percentage of CPU resources that should be reserved in decimal format (e.g. 1 = 100%, 0.2 = 20%)

    .PARAMETER cpuLimit
    The limit in Mhz for the CPU of the VM

    .PARAMETER cpuShares
    The number of shares for CPU resources for the VM

    .PARAMETER memory
    The memory in MB for the VM

    .PARAMETER memoryReservationGuarantee
    The Percentage of Memory resources that should be reserved in decimal format (e.g. 1 = 100%, 0.2 = 20%)

    .PARAMETER memoryLimit
    The limit for the memory in MB for the VM

    .PARAMETER memoryShares
    The number of shares for Memory resources for the VM

    .PARAMETER extraConfigs
    A hashtable of any Advanced VM Configurations to set for the VM

    .EXAMPLE
    New-CIVMSizingPolicy -Name "Example" -Description "A test" -cpuSpeed 200 -cpuCount 2 -cpuReservationGuarantee 0.2
    Creates a new VM Sizing Policy with the Name "Example" which sets the CPU speed to 200Mhz and the vCPU count to 2 with a 20% CPU reservation

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-01-21
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [string] $Name,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [string] $Description,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [int] $cpuSpeed,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [int] $cpuCount,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [int] $coresPerSocket,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [double] $cpuReservationGuarantee,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [int] $cpuLimit,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [int] $cpuShares,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [int] $memory,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [int] $memoryReservationGuarantee,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [int] $memoryLimit,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [int] $memoryShares,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [Hashtable] $extraConfigs
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null
    # Check if a VM Sizing Policy with the name already exists
    if((Get-CIVDCComputePolicy -Name $Name -SizingPolicyOnly).Count -ne 0){
        throw "A VM Sizing Policy with the Name $Name already exists. Please remove it before attempting to create a new Sizing Policy or use the Set-CIVMSizingPolicy cmdlet to adjust the settings."
    }
    # Create the VM Placement Policy Object (only mandatory property is Name)
    [HashTable] $VMPlacementPolicy = @{
        name = $Name
    }
    # Check for each property if it has been provided and add it to the object payload
    if($PSBoundParameters.ContainsKey('Description')){
        $VMPlacementPolicy.Add("description",$Description)
    }
    if($PSBoundParameters.ContainsKey('cpuSpeed')){
        $VMPlacementPolicy.Add("cpuSpeed",$cpuSpeed)
    }
    if($PSBoundParameters.ContainsKey('cpuCount')){
        $VMPlacementPolicy.Add("cpuCount",$cpuCount)
    }
    if($PSBoundParameters.ContainsKey('coresPerSocket')){
        $VMPlacementPolicy.Add("coresPerSocket",$coresPerSocket)
    }
    if($PSBoundParameters.ContainsKey('cpuReservationGuarantee')){
        $VMPlacementPolicy.Add("cpuReservationGuarantee",$cpuReservationGuarantee)
    }
    if($PSBoundParameters.ContainsKey('cpuLimit')){
        $VMPlacementPolicy.Add("cpuLimit",$cpuLimit)
    }
    if($PSBoundParameters.ContainsKey('cpuShares')){
        $VMPlacementPolicy.Add("cpuShares",$cpuShares)
    }
    if($PSBoundParameters.ContainsKey('memory')){
        $VMPlacementPolicy.Add("memory",$memory)
    }
    if($PSBoundParameters.ContainsKey('memoryReservationGuarantee')){
        $VMPlacementPolicy.Add("memoryReservationGuarantee",$memoryReservationGuarantee)
    }
    if($PSBoundParameters.ContainsKey('memoryLimit')){
        $VMPlacementPolicy.Add("memoryLimit",$memoryLimit)
    }
    if($PSBoundParameters.ContainsKey('memoryShares')){
        $VMPlacementPolicy.Add("memoryShares",$memoryShares)
    }
    if($PSBoundParameters.ContainsKey('extraConfigs')){
        $VMPlacementPolicy.Add("extraConfigs",$extraConfigs)
    }
    # Set the Web Request Parameters
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/vdcComputePolicies"
        Method = "Post"
        APIVersion = 33
        Data = (ConvertTo-JSON $VMPlacementPolicy -Depth 100)
    }
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    return $Response
}



