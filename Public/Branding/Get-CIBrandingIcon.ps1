function Get-CIBrandingIcon(){
    <#
    .SYNOPSIS
    Downloads the currently defined branding icon for a vCloud Director instance.

    .DESCRIPTION
    Downloads the currently defined branding icon for a vCloud Director instance.

    .PARAMETER OutputFileName
    The file path to save the icon file.

    .EXAMPLE
    Get-CIBrandingIcon -OutputFileName "D:\icon.png"
    Returns the Branding Icon and saves it as D:\icon.png

    .NOTES
    These cmdlets were refactored based on the original work of Jon Waite. The original implementation is available from https://raw.githubusercontent.com/jondwaite/vcd-h5-themes/master/vcd-h5-themes.psm1

    Per-tenant branding requires functionality first introduced in vCloud Director 9.7 (API Version 32.0) and will *NOT* work with any prior release.
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()]  [string] $OutputFileName
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null
    # Set the location to the current folder
    $OutputFileName = "$($pwd.Path)\" + $OutputFileName

    # Define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/branding/icon"
        Method = "Get"
        Headers = @{
            "x-vcloud-authorization" = $global:DefaultCIServers.SessionId;
            "Accept" = 'image/png;version=33.0, image/x-icon;version=33.0'
        }
        OutFile = $OutputFileName
        SkipCertificateCheck = $true
    }
    # Make the API call and return the result
    try{
        Invoke-WebRequest @RequestParameters
    } catch {
        Write-Error ("Error occurred retrieving icon, Status Code is $($_.Exception.Response.StatusCode.Value__).")
        return
    }
}