function Test-CIServerConnection(){
    <#
    .SYNOPSIS
    This cmdlet is used to check if a connection to a vCloud Service exists and extends the variables to leverage the Cloud API endpoint.

    .DESCRIPTION
    This cmdlet is used to check if a connection to a vCloud Service exists and extends the variables to leverage the Cloud API endpoint.

    This cmdlet only supports connections to a single vCloud Director instance. If multiple connections are present an Exception is thrown.

    .EXAMPLE
    Test-CIServerConnection
    Returns $true if there is a valid connection otherwise returns $false

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-10
	VERSION: 1.0
    #>
    if($global:DefaultCIServers.Count -eq 0){
        throw "You are not currently connected to a valid vCloud Director Service. Please connecting using the Connect-CIServer cmdlet before continuing."
    } elseif($global:DefaultCIServers.Count -gt 1){
        throw "Connections to multiple Servers is not supported. If you are connected to multiple servers please disconnect them first and retry this cmdlet."
    } else {
        # Check if the connection properties for CloudAPI exist and if not add them
        if(!(Get-Member -inputobject $global:DefaultCIServers[0] -name "CloudAPIServiceURI" -Membertype NoteProperty)){
            # Add the Cloud API Endpoint to the Global
            $global:DefaultCIServers | Add-Member -NotePropertyName "CloudAPIServiceURI" -NotePropertyValue "https://$($global:DefaultCIServers.ServiceUri.Host)/cloudapi"
        }
        # Next check the API Versions Supported and add these if they do not exist
        if(!(Get-Member -inputobject $global:DefaultCIServers[0] -name "APIVersionsSupported" -Membertype NoteProperty)){
            [xml]$APIVersionsSupported = Invoke-WebRequest -Uri "$($global:DefaultCIServers.ServiceURI.AbsoluteUri)versions" -Method Get -Headers @{"Accept"='application/*+xml'} -SkipCertificateCheck
            [double[]] $APIVersions = (($APIVersionsSupported.SupportedVersions.VersionInfo | Where-Object { $_.deprecated -eq $false } | Sort-Object Version -Descending -Unique).Version)
            $global:DefaultCIServers | Add-Member -NotePropertyName "APIVersionsSupported" -NotePropertyValue $APIVersions
        }
        return $true
    }
}

