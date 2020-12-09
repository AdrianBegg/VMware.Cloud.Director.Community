function Set-CISite(){
    <#
    .SYNOPSIS
    Adjusts the Site Name for the currently connected Director Director Site

    .DESCRIPTION
    Adjusts the Site Name for the currently connected Director Director Site

    .PARAMETER SiteName
    The Site Name

    .EXAMPLE
    Set-CISite -SiteName "Site-A"
    Sets the Site Name for the currently connected Cloud Director site to "Site-A"

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-01-08
	VERSION: 1.0
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $SiteName
    )
    # Next we need to retireve the Site Name for the local site
    [Hashtable] $ImportRequestParameters = @{
        URI = "$($global:DefaultCIServers.ServiceUri)site"
        Method = "Get"
        APIVersion = 33
        APIType = "Legacy"
    }
    [xml] $LocalSiteXML = (Invoke-CICloudAPIRequest @ImportRequestParameters).RawData

    # Expand the cmdlet in the future to support other updates, just need to update the site name for now
    if($PSBoundParameters.ContainsKey("SiteName")){
        $LocalSiteXML.Site.name = $SiteName
        [Hashtable] $ImportRequestParameters = @{
            URI = "$($global:DefaultCIServers.ServiceUri)site"
            Method = "Put"
            APIVersion = 33
            APIType = "Legacy"
            CustomContentType = "application/vnd.vmware.vcloud.site+xml"
            Data = $LocalSiteXML
        }
        [xml] (Invoke-CICloudAPIRequest @ImportRequestParameters).RawData
    }
}