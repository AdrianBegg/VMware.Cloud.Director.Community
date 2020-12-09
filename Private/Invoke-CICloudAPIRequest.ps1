
function Invoke-CICloudAPIRequest(){
    <#
    .SYNOPSIS
    This cmdlet will send a REST API call to the Cloud Director Cloud API Service and return an object containing the headers and the data payload to the caller.

    .PARAMETER URI
    The fully qualified URI of the vCloud API endpoint.

    .PARAMETER Method
    The HTTP Method to send for the API call

    .PARAMETER APIVersion
    The API version to be used for the API call

    .PARAMETER Data
    JSON data to be sent as the HTTP Payload in the API call. For a Get request the data is sent as a Query Parameter set.

    .PARAMETER Headers
    A Hashtable containing additional headers that should be passed during the API call. Any default headers will be overwritten.

    .PARAMETER InFile
    Optionally for a file upload the file to upload

    .NOTES
    This cmdlet obeys the ProxyPolicy and InvalidCertificateAction parameters set in the VMWare PowerCLI Configuration.
    There is a limitation for PowershellCore that at the cmdlet can only be used with the "UseSystemProxy" policy on Windows netsh winhttp show proxy settings; this will be changed in future

    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-10
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateScript({[system.uri]::IsWellFormedUriString($_,[System.UriKind]::Absolute)})] [string] $URI,
        [Parameter(Mandatory=$True)]
            [ValidateSet("Get","Put","Post","Delete","Patch")] [string] $Method,
        [Parameter(Mandatory=$True)]
            [ValidateSet(34,33,32,31,30)] [int] $APIVersion,
        [Parameter(Mandatory=$False)]
            [ValidateSet("Legacy","CloudAPI")] [string] $APIType = "CloudAPI",
        [Parameter(Mandatory=$False)]
            [ValidateSet("XML","JSON")] [string] $LegacyAPIDataType = "XML",
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [string] $CustomContentType,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] $Data,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] $InFile,
        [Parameter(Mandatory=$False)]
            [Hashtable] $Headers
	)
    # Validate the environment is ready based on the input parameters
    if(!(Test-CIServerConnection)){
        Break
    }

    # Construct the headers for the API call
    $APIHeaders = @{
            'x-vcloud-authorization' = $global:DefaultCIServers.SessionId
    }
    # Add the API Version Header (CloudAPI did not exist before API version 30)
    if($APIType -eq "CloudAPI"){
        if($APIVersion -lt 30){
            throw "The provided API Version is not supported by this cmdlet. Please check the compatibility and try again"
        } else {
            $APIHeaders.Add("Content-Type","application/json")
            $APIHeaders.Add("Accept","application/json;version=$APIVersion.0")
        }
    } else {
        # Legacy API generally uses XML however only can use a JSON header
        if($LegacyAPIDataType -eq "XML"){
            $APIHeaders.Add("Content-Type","application/*+xml")
            $APIHeaders.Add("Accept","application/*+xml;version=$APIVersion.0")
        } elseif($LegacyAPIDataType -eq "JSON"){
            $APIHeaders.Add("Content-Type","application/*+json")
            $APIHeaders.Add("Accept","application/*+json;version=$APIVersion.0")
        }
    }
    if($PSBoundParameters.ContainsKey("CustomContentType")){
        $APIHeaders."Content-Type" = $CustomContentType
    }
    # Check if any custom headers have been provided and if they have set them
    if($Headers.Count -ne 0){
        foreach($Key in $Headers.Keys){
            $APIHeaders.$Key = $Headers.$Key
        }
    }

    # Create a Hashtable with base paramters to use for splatting to Invoke-WebRequest
    $HashInvokeArguments = @{
        Uri = $URI
        Method = $Method
        Headers = $APIHeaders
    }
    # Next check the PowerCLI Proxy policy to determine if what Proxy Policy should be used for the API call and set accordingly
    if((Get-PowerCLIConfiguration -Scope "User" | Select-Object ProxyPolicy).ProxyPolicy -eq "NoProxy") {
        $HashInvokeArguments.Add("NoProxy",$true)
    } elseif((Get-PowerCLIConfiguration -Scope "User" | Select-Object ProxyPolicy).ProxyPolicy -eq "UseSystemProxy") {
        # Check the PowerShell edition first
        if($Global:PSEdition -eq "Desktop"){
            $Proxy = ([System.Net.WebRequest]::GetSystemWebProxy()).GetProxy($URI)
            $HashInvokeArguments.Add("Proxy",$Proxy.AbsoluteUri)
            $HashInvokeArguments.Add("ProxyUseDefaultCredentials",$true)
        } elseif($Global:PSEdition -eq "Core") {
            # For PowerShell Core you can not use the [System.Net.WebProxy]::GetDefaultProxy() or [System.Net.WebRequest]::GetSystemWebproxy() static method as its not supported
            # Really not happy with this implementation but temporary until can write a better handler or support is added for GetDefaultProxy static method
            $Proxy = Get-WinHttpProxy
            if($Proxy.'Winhttp proxy' -ne "Direct Access"){
                [string] $ProxyString = "http://$($Proxy.'Winhttp proxy')"
                $HashInvokeArguments.Add("Proxy",$ProxyString)
                $HashInvokeArguments.Add("ProxyUseDefaultCredentials",$true)
            }
        }
    }
    # Check if the Certificate Check should be performed and add the argument if not
    if((Get-PowerCLIConfiguration -Scope "User" | Select-Object InvalidCertificateAction).InvalidCertificateAction -eq "Ignore") {
        $HashInvokeArguments.Add("SkipCertificateCheck",$true)
    }

    # Check if data has been provided
    if($PSBoundParameters.ContainsKey("Data")){
        $HashInvokeArguments.Add("Body", $Data)
    }
    # Check if we are sending a file
    if($PSBoundParameters.ContainsKey("Data")){
        $HashInvokeArguments.Add("InFile", $InFile)
    }
    # Now try and make the API call
    try{
        $Request = Invoke-WebRequest @HashInvokeArguments
        $objResponse = New-Object System.Management.Automation.PSObject
        $objResponse | Add-Member Note* Headers $Request.Headers
        if($null -ne $Request.Content){
            try{
                $objResponse | Add-Member Note* JSONData (ConvertFrom-JSON ($Request.Content))
            } catch {
                # For non-JSON payloads/check if an encloding problem has occurred
                try{
                    $objResponse | Add-Member Note* JSONData (ConvertFrom-JSON ([System.Text.Encoding]::Ascii.GetString($Request.Content)))
                } catch {
                    $objResponse | Add-Member Note* RawData $Request.Content
                }
            }
        }
        $objResponse
    } catch {
        if($_.Exception.Response.StatusCode -eq "Unauthorized"){
            throw [System.UnauthorizedAccessException] "An Unauhorized Exception was thrown attempting to make the API call to $URI. Please check that you have the required permissions to execute this call and that you have a current connected session."
        } else {
            throw "An error occurred making an API call to $URI. Exception details: $($_.Exception)"
        }
    }
}