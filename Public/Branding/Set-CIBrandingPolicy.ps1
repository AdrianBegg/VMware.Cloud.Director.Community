Function Set-CIBrandingPolicy(){
    <#
    .SYNOPSIS
    Sets the currently defined branding settings for a vCloud Director instance.

    .DESCRIPTION
    Sets the currently defined branding settings for a vCloud Director instance.

    .PARAMETER Tenant
    Optionally the Tenant to apply the branding policy against. If not specified the settings are applied globally.

    .PARAMETER portalName
    An optional description of the portal which will be displayed at login and in the vCloud Director banner in every page.

    .PARAMETER portalColor
    An optional hex-formatted color values (in upper case) which determine the default portal background banner color (e.g. '#1A2A3A'). If not specified the existing value will be unchanged. If specified as the string 'Remove' will remove any defined portal color value. 
    
    .PARAMETER Theme
    Optionally the Theme to apply.

    .PARAMETER customLinks
    An object consisting of custom URL links to be included in the vCloud Director portal. Links will be validated by the vCloud API and rejected if they are not properly formed URL specifications. 

    .EXAMPLE
    An example

    .NOTES
    These cmdlets were refactored based on the original work of Jon Waite. The original implementation is available from https://raw.githubusercontent.com/jondwaite/vcd-h5-themes/master/vcd-h5-themes.psm1

    Per-tenant branding requires functionality first introduced in vCloud Director 9.7 (API Version 32.0) and will *NOT* work with any prior release.
    #>
    Param(
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $Tenant,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [string] $portalName,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [string] $portalColor,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [string] $Theme,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [System.Object] $customLinks
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null
    # First retireve the current branding policy and set a flag to track changes
    [bool] $SettingChanged = $false
    if($PSBoundParameters.ContainsKey("Tenant")){
        $BrandingPolicy = Get-CIBrandingPolicy -Tenant $Tenant
    } else {
        $BrandingPolicy = Get-CIBrandingPolicy
    }

    # Now see if any changes were provided and adjust them
    if($PSBoundParameters.ContainsKey("portalName")){
        $BrandingPolicy.portalName = $portalName
        $SettingChanged = $true
    }
    if($PSBoundParameters.ContainsKey("portalColor")){
        if ($portalColor -eq "Remove") {
            $BrandingPolicy.portalColor = ""
        } else {
            $BrandingPolicy.portalColor = $portalColor
        }
        $SettingChanged = $true
    }
    if($PSBoundParameters.ContainsKey("Theme")){
        $NewTheme = (Get-CIBrandingThemes -ThemeName $Theme)
        if($NewTheme.Count -eq 0){
            throw "A theme with the name $Theme cannot be found."
        } else {
            $BrandingPolicy.selectedTheme = $NewTheme
        }
        $SettingChanged = $true
    }
    if($PSBoundParameters.ContainsKey("customLinks")){
        $BrandingPolicy.customLinks = $customLinks
        $SettingChanged = $true
    }
    # Now check if an update has actually been made and make the API call
    if($SettingChanged){
        [Hashtable] $RequestParameters = @{
            URI = "$($global:DefaultCIServers.CloudAPIServiceURI)/branding"
            Method = "Put"
            APIVersion = 33
            Data = ($BrandingPolicy | ConvertTo-Json)
        }
        # Add the tenant filter if provided
        if($PSBoundParameters.ContainsKey("Tenant")){
            $RequestParameters.URI += "/tenant/$Tenant"
        }
        # Make the API call and return the result
        $Response = (Invoke-CICloudAPIRequest @RequestParameters).JSONData
        return $Response
    } else {
        Write-Warning "No changes to the current settings were provided. Nothing has been performed."
    }
}