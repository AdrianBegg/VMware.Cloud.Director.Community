Function Get-CIBrandingPolicy{
    <#
    .SYNOPSIS
    Gets the currently defined branding settings for a vCloud Director instance.

    .DESCRIPTION
    Provides a simple method to retrieve the current defined branding settings in a vCloud Director instance.

    .PARAMETER Tenant
    Optionally, the vCloud Director Tenant scope to retrieve branding policy from, if no custom branding has been specified for the given tenant then the system-level branding will be returned.

    .OUTPUTS
    The currently defined branding settings as a PSObject

    .EXAMPLE
    Get-CIBrandingPolicy
    Returns the system default Branding Policy

    .EXAMPLE
    Get-CIBrandingPolicy -Tenant PigeonNuggets
    Returns the Branding Policy that is applied for the Tenant Org "PigeonNuggets"

    .NOTES
    These cmdlets were refactored based on the original work of Jon Waite. The original implementation is available from https://raw.githubusercontent.com/jondwaite/vcd-h5-themes/master/vcd-h5-themes.psm1

    Per-tenant branding requires functionality first introduced in vCloud Director 9.7 (API Version 32.0) and will *NOT* work with any prior release.
    #>
    Param(
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $Tenant
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/branding"
        Method = "Get"
        APIVersion = 33
    }
    # Add the tenant filter if provided
    if($PSBoundParameters.ContainsKey("Tenant")){
        $RequestParameters.URI += "/tenant/$Tenant"
    }
    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    return $Response
}