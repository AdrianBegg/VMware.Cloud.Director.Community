 function Remove-CIBrandingTheme(){
    <#
    .SYNOPSIS
    Removes a (custom) theme for vCloud Director.
    
    .DESCRIPTION
    Removes a (custom) theme for vCloud Director.
    
    .PARAMETER ThemeName
    A name for the custom theme
    
    .EXAMPLE
    Remove-CIBrandingTheme -ThemeName Example
    Removes the vCloud Theme named "Example" in the currently connected installation.
    
    .NOTES
    These cmdlets were refactored based on the original work of Jon Waite. The original implementation is available from https://raw.githubusercontent.com/jondwaite/vcd-h5-themes/master/vcd-h5-themes.psm1

    Per-tenant branding requires functionality first introduced in vCloud Director 9.7 (API Version 32.0) and will *NOT* work with any prior release.
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()]  [string] $ThemeName
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # Check if the theme exists
    if((Get-CIBrandingThemes -ThemeName $ThemeName).Count -eq 0){
        throw "A Theme with the name $ThemeName does not exists in the currently connected environment."
    }
    [PSCustomObject] $Data = @{
        name = $ThemeName
    } 
    # Define basic request properties for the API call
    [Hashtable] $RequestParameters = @{
        URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/branding/themes/$ThemeName"
        Method = "Delete"
        APIVersion = 33
        Data = ($Data | ConvertTo-Json)
    }

    # Make the API call and return the result
    $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
    return $Response
}