function Publish-CIBrandingLogo(){
    <#
    .SYNOPSIS
    Uploads a graphic file (PNG format) to be used as the vCloud site Logo, if no Tenant is specified this will be the default Logo.
    
    .DESCRIPTION
    Uploads a graphic file (PNG format) to be used as the vCloud site Logo, if no Tenant is specified this will be the default Logo.
    
    .PARAMETER LogoFile
    The path to the PNG file containing the Logo to be uploaded

    .PARAMETER Tenant
    Optionally the tenant to apply the Logo
    
    .EXAMPLE
    Publish-CIBrandingLogo -LogoFile logo.png
    
    .NOTES
    These cmdlets were refactored based on the original work of Jon Waite. The original implementation is available from https://raw.githubusercontent.com/jondwaite/vcd-h5-themes/master/vcd-h5-themes.psm1

    Per-tenant branding requires functionality first introduced in vCloud Director 9.7 (API Version 32.0) and will *NOT* work with any prior release.
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [string]$LogoFile,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $Tenant
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null
    # TO DO: Add check that the Icon file exists
    
    # Define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/branding/logo"
        Method = "Put"
        Headers = @{
            "x-vcloud-authorization" = $global:DefaultCIServers.SessionId;
            "Accept" = '*/*;version=33.0'
        }
        ContentType = "image/png"
        SkipCertificateCheck = $true
        InFile = $LogoFile
    }
    # Add the tenant filter if provided
    if($PSBoundParameters.ContainsKey("Tenant")){
        $RequestParameters.URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/tenant/$Tenant/branding/logo"
    }
    # Make the API call and return the result
    try{
        Invoke-WebRequest @RequestParameters | Out-Null
    } catch {
        Write-Error ("Error occurred obtaining uploading logo file, Status Code is $($_.Exception.Response.StatusCode.Value__).")
        return
    }
}