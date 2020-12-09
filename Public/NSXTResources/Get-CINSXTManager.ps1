function Get-CINSXTManager(){
    <#
    .SYNOPSIS
    Returns a collection of NSX-T Managers that are registered with the connected Cloud Director

    .DESCRIPTION
    Returns a collection of NSX-T Managers that are registered with the connected Cloud Director

    .PARAMETER Name
    The Name of the NSX-T Manager

    .EXAMPLE
    Get-CINSXTManager
    Returns all NSX-T Managers that are registered with the connected Cloud Director

    .EXAMPLE
    Get-CINSXTManager -Name "Test-NSXT"
    Returns the NSX-T Manager "Test-NSXT" if one exists in the connected Cloud Director isntance

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-17
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$False, ParameterSetName = "ByName")]
            [ValidateNotNullorEmpty()] [String] $Name
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Query the installation for all NSX-T Managers
    [Hashtable] $NSXTRequestArgs = @{
        type = "nsxTManager"
        page = 1
        pageSize = 128
        links = "true"
        format = "records"
    }
    [Hashtable] $NSXTRequestParameters = @{
        URI = "$($global:DefaultCIServers.ServiceUri)query"
        Method = "Get"
        APIVersion = 33
        APIType = "Legacy"
        Data = $NSXTRequestArgs
    }
    $NSXTManagers = ([xml](Invoke-CICloudAPIRequest @NSXTRequestParameters).RawData).QueryResultRecords.NsxTManagerRecord
    # Check if a filter was specified
    if($PSBoundParameters.ContainsKey('Name')){
        $NSXTManagers = $NSXTManagers | Where-Object{$_.name -eq $Name}
    }
    # Initalise a collection to store the results
    $arrListNSXManagers = New-Object -TypeName "System.Collections.ArrayList"
    foreach($NSXTManagerRef in $NSXTManagers){
        # Now return the full object from the API
        [Hashtable] $NSXTRequestParameters = @{
            URI = $NSXTManagerRef.href
            Method = "Get"
            APIVersion = 33
            APIType = "Legacy"
        }
        $NSXTAPIObject = ([xml](Invoke-CICloudAPIRequest @NSXTRequestParameters).RawData).NsxTManager
        $arrListNSXManagers.Add($NSXTAPIObject) | Out-Null
    }
    return $arrListNSXManagers
}