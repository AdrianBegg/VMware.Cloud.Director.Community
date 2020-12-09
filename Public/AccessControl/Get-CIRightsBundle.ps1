function Get-CIRightsBundle(){
    <#
    .SYNOPSIS
    Returns a collection of Cloud Director Rights Bundles.

    .DESCRIPTION
    Returns a collection of Cloud Director Rights Bundles.

    .PARAMETER Name
    Optionally a Rights Bundle Name to filter results

    .PARAMETER Id
    Optionally a Rights Bundle Id to filter results

    .EXAMPLE
    Get-CIRightsBundle 
    Returns a collection of all Rights Bundles on the currently connected Cloud Director.

    .EXAMPLE
    Get-CIRightsBundle -Name "Default Rights Bundle" -IncludeRights 
    Returns the Default Rights Bundle including all of the Rights applied to the Bundle

    .EXAMPLE
    Get-CIRightsBundle -Id "urn:vcloud:rightsBundle:6aade45b-8b54-4908-8abe-4d1cf8d646d2"
    Returns the Rights Bundle with the Id "urn:vcloud:rightsBundle:6aade45b-8b54-4908-8abe-4d1cf8d646d2"
    
	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-05-13
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$False, ParameterSetName = "ByName")]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$False, ParameterSetName = "ById")]
            [ValidateNotNullorEmpty()] [String] $Id,
        [Parameter(Mandatory=$False)]
            [switch] $IncludeRights
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
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/rightsBundles"
        Method = "Get"
        APIVersion = 34
        Data = $APIParameters
    }
    # Next we need to determine if we need to filter the results at all - to prevent multiple API calls process subset
    if($PSBoundParameters.ContainsKey('Id')){
        # If Id was provided just execute and return the result
        $RequestParameters.URI += "/$Id"
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        $colRightsBundles = $Response
    } elseif($PSBoundParameters.ContainsKey('Name')){
        $APIParameters.Add("filter",(Format-FIQL @{name = "==$Name"}))
        # Make the API call to retrieve all of the Rights
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        # Check if multiple values are present
        if($Response.values.Count -gt 0){
            # Store the intermediate results
            $colRightsBundles = $Response.values
            # Check there are more results then are in the current page continue to query until all items have been returned
            if($Response.pageCount -ne 0){
                while ($Response.pageCount -gt $Response.page){
                    # Increment to the next page and add the results
                    ($APIParameters.page)++ | Out-Null
                    $RequestParameters.Data = $APIParameters
                    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
                    $colRightsBundles += $Response.values
                }
            }
        }
    }

    # Finally check if we should include the Rights in the response
    if($colRightsBundles.Count -ne 0){
        if($PSBoundParameters.ContainsKey('IncludeRights')){
            foreach($objRightBundle in $colRightsBundles){
                # First define the request "Body" with any filters or mandatory parameters
                [Hashtable] $RightsAPIParameters = @{
                    page = 1
                    pageSize = 128
                }
                # Next define basic request properties for the API call
                [Hashtable] $RightRequestParameters = @{
                    URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/1.0.0/rightsBundles/$($objRightBundle.id)/rights"
                    Method = "Get"
                    APIVersion = 34
                    Data = $RightsAPIParameters
                }
                # Make the API call to retrieve all of the Rights
                $RightsResponse = (Invoke-CICloudAPIRequest @RightRequestParameters).JSONData
                # Store the intermediate results
                $colRights = $RightsResponse.values
                # Check there are more results then are in the current page continue to query until all items have been returned
                if($RightsResponse.pageCount -ne 0){
                    while ($RightsResponse.pageCount -gt $RightsResponse.page){
                        # Increment to the next page and add the results
                        ($RightsAPIParameters.page)++ | Out-Null
                        $RightRequestParameters.Data = $RightsAPIParameters
                        $RightsResponse = (Invoke-CICloudAPIRequest @RightRequestParameters).JSONData
                        $colRights += $RightsResponse.values
                    }
                }            
                # Add the rights to the RightsBundle object
                $objRightBundle | Add-Member Note* rights $colRights
            }
        }
    }
    return $colRightsBundles
}

