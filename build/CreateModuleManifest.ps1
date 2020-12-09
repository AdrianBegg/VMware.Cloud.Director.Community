# Basic script to build the module and install it in Dev
[string] $BasePath = $pwd.Path.Trim("\build")

# Get a collection of files to add to the manifest
Set-Location $BasePath
$colPrivFunctionFiles = (Get-ChildItem .\Private\ -Recurse)
$colPublicFunctionFiles = (Get-ChildItem .\Public\ -Recurse)
$NestedModules = ($colPrivFunctionFiles | Resolve-Path -Relative | ?{$_.EndsWith(".ps1")}) + ($colPublicFunctionFiles | Resolve-Path -Relative | ?{$_.EndsWith(".ps1")})

# Now get a list of Public Functions to expose to end users
$colPublicFunctions = ($colPublicFunctionFiles | Where-Object {$_.Extension -eq ".ps1"}).BaseName

$manifest = @{
    Path              = "$BasePath\VMware.Cloud.Director.Community.psd1"
    ModuleVersion     = '0.1.2'
    Author            = 'Adrian Begg'
    Copyright         = '2020 Adrian Begg. All rights reserved.'
    Description       = 'Yet another community PowerShell modules to expose REST API functions for VMware Cloud Director 10.X functions as PowerShell cmdlets.'
    ProjectUri        = 'https://github.com/AdrianBegg/VMware.Cloud.Director.Community'
    LicenseUri        = 'https://raw.githubusercontent.com/AdrianBegg/VMware.Cloud.Director.Community/master/LICENSE'
    CompatiblePSEditions = "Desktop","Core"
    PowerShellVersion = '7.1'
    NestedModules = @($NestedModules.TrimStart(".\"))
    FunctionsToExport= @(($colPublicFunctions))
    RequiredModules = @("VMware.VimAutomation.Cloud")
}
New-ModuleManifest @manifest