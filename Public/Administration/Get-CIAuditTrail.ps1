function Get-CIAuditTrail(){
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $EventId,
            [ValidateNotNullorEmpty()] [String] $TaskId,
            [ValidateNotNullorEmpty()] [String] $EventType,
            [ValidateNotNullorEmpty()] [DateTime] $OccurredAfter,
            [ValidateNotNullorEmpty()] [DateTime] $OccurredBefore,
            [ValidateSet("SUCCESS","FAILURE")] [String] $EventStatus,
            [ValidateNotNullorEmpty()] [String] $Organisation,
            [ValidateNotNullorEmpty()] [String] $Owner

    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # First define the request "Body" with any filters or mandatory parameters
    [Hashtable] $APIParameters = @{
        page = 1
        pageSize = 128
    }
    # Next define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/auditTrail"
        Method = "Get"
        APIVersion = 33
        Data = $APIParameters
    }
    # Create a Hashtable for FIQL filters
    [Hashtable] $Filters = @{}
    # Note: The API does not support filerting on the following (filtering of these must happen locally): EventId, taskId, cellId, serviceNamespace, eventStatus
    # Check if any filters have been provided and add to the FIQL filter
    if($PSBoundParameters.ContainsKey("OccurredAfter")){
        # Cast the DateTime provided to UTC and to ISO8601 format with only 3 decimal palces for the API
        $Filters.Add("timestamp","=ge=$($OccurredAfter.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ"))")
    }
    if($PSBoundParameters.ContainsKey("OccurredBefore")){
        # Cast the DateTime provided to UTC and to ISO8601 format with only 3 decimal palces for the API
        $Filters.Add("timestamp","=le=$($OccurredBefore.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ"))")
    }
    if($Filters.Count -gt 0){
        $APIParameters.Add("filter",(Format-FIQL -Parameters $Filters))
    }

    # Make the API call to retrieve the AuditTrail
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    # Store the intermediate results
    $colAuditTrail = $Response.values
    # Check there are more results then are in the current page continue to query until all items have been returned

    if($Response.pageCount -ne 0){
        while ($Response.pageCount -gt $Response.page){
            # Increment to the next page and add the results
            ($APIParameters.page)++ | Out-Null
            $RequestParameters.Data = $APIParameters
            $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
            $colAuditTrail += $Response.values
        }
    }
    # Now returns the collection of Audit Trail events
    if($PSBoundParameters.ContainsKey("EventId")){
        # Filter the results
    }
    if($PSBoundParameters.ContainsKey("EventType")){
        # Filter the results
    }

    if($PSBoundParameters.ContainsKey("TaskId")){
        # Filter the results
    }
    return $colAuditTrail
}