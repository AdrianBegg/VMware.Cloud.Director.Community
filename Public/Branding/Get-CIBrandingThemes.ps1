Function Get-CIBrandingThemes(){
    <#
    .SYNOPSIS
    Gets a list of any themes defined in the vCloud Director installation.
    
    .DESCRIPTION
    Gets a list of any themes defined in the vCloud Director installation.
    
    .PARAMETER ThemeName
    An optional parameter which specifies a theme name to try and match.
    
    .EXAMPLE
    Get-CIBrandingThemes
    Returns all of the currently available themes installed
    
    .NOTES
    These cmdlets were refactored based on the original work of Jon Waite. The original implementation is available from https://raw.githubusercontent.com/jondwaite/vcd-h5-themes/master/vcd-h5-themes.psm1

    Per-tenant branding requires functionality first introduced in vCloud Director 9.7 (API Version 32.0) and will *NOT* work with any prior release.
    #>
    Param(
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $ThemeName
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/branding/themes"
        Method = "Get"
        APIVersion = 33
    }
    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    # Add the tenant filter if provided
    if($PSBoundParameters.ContainsKey("ThemeName")){
        return ($Response | Where-Object { $_.name -eq $ThemeName })
    } else {
        return $Response
    }
}