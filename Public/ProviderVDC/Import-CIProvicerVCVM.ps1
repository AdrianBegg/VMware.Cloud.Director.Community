function Import-CIProvicerVCVM(){
    <#
    .SYNOPSIS
    Imports a Virutal Machine from the Resource vCenter into Cloud Director

    .DESCRIPTION
    Imports a Virutal Machine from the Resource vCenter into Cloud Director

    .PARAMETER vCenterName
    The Resource vCenter name

    .PARAMETER VMName
    The VM Name

    .PARAMETER OrgVDC
    The Org VDC to import the VM

    .PARAMETER ImportAsTemplate
    If set imports as a vApp Template

    .PARAMETER CatalogName
    The Cloud Director Catalog to import the template

    .EXAMPLE
    Import-CIProvicerVCVM -vCenterName "vCenter1" -VMName "photon-ova" -OrgVDC "PublicCatalog" -ImportAsTemplate -CatalogName "Public Catalog - vApp"
    Imports the VM photon-ova as a vApp Template into the Catalog PublicCatalog  - vApp in the OrgVDC PublicCatalog

	.NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2019-12-20
	VERSION: 1.0
    #>

    Param(
        [Parameter(Mandatory=$True, ParameterSetName = "vApp")]
        [Parameter(Mandatory=$True, ParameterSetName = "vAppTemplate")]
            [ValidateNotNullorEmpty()] [String] $vCenterName,
            [ValidateNotNullorEmpty()] [String] $VMName,
            [ValidateNotNullorEmpty()] [String] $OrgVDC,
        [Parameter(Mandatory=$True, ParameterSetName = "vAppTemplate")]
            [switch]$ImportAsTemplate,
        [Parameter(Mandatory=$True, ParameterSetName = "vAppTemplate")]
            [ValidateNotNullorEmpty()] [String] $CatalogName
    )
    # Always check if we are connected first
    Test-CIServerConnection | Out-Null

    # First check if the vCenter exists
    $ProviderVC = Get-CIProviderVC -Name $vCenterName
    if($ProviderVC.Count -eq 0){
        throw "A Provider vCenter with the name $vCenterName is not currently registered with the connected Cloud Director. Please check the name and try again."
    }
    # Next check the destination objects
    $OrgVDCObject = Get-OrgVDC -Name $OrgVDC -ErrorAction:SilentlyContinue
    if($OrgVDCObject.Count -eq 0){
        throw "The OrgVDC $OrgVDC can not be found. Check that it exists and you are logged into an Org/Scope that has permission to the object."
    }
    # If importing to a calalog check that the catalog exists
    if($PSBoundParameters.ContainsKey("ImportAsTemplate")){
        $CatalogObject = Get-Catalog -Name $CatalogName -ErrorAction:SilentlyContinue
        if($CatalogObject.Count -eq 0){
            throw "The Catalog $CatalogName can not be found. Check that it exists and you are logged into an Org/Scope that has permission to the object."
        }
    }

    # Next query a list of VMs available in the inventory for import
    [Hashtable] $VIVMRequestParameters = @{
        URI = "$($ProviderVC.href)/vmsList"
        Method = "Get"
        APIVersion = 33
        APIType = "Legacy"
    }
    [xml] $VIVMXML = ((Invoke-CICloudAPIRequest @VIVMRequestParameters).RawData)
    # Check if the provided VM exists
    $vmImportObject = $VIVMXML.VmObjectRefsList.VmObjectRef | Where-Object {$_.name -eq $VMName}
    if($vmImportObject.Count -eq 0){
        throw "An importable VM with name $VMName can not be found in vCenter $vCenterName. Please check and try again."
    }

    # Next Import the VM
    if($PSBoundParameters.ContainsKey("ImportAsTemplate")){
        $ImportURI = "$($ProviderVC.href)/importVmAsVAppTemplate"
        [string] $ContentType = "application/vnd.vmware.admin.importVmAsVAppTemplateParams+xml"

        # Construct some ugly payload as I have no clue how to generate clean XML in PS
        $CRLF = [Environment]::NewLine
        $xmlPayload  = "<?xml version=""1.0"" encoding=""UTF-8""?>$CRLF"
        $xmlPayload += "<ImportVmAsVAppTemplateParams xmlns=""http://www.vmware.com/vcloud/extension/v1.5"" name=""$($vmImportObject.name)"" sourceMove=""true"">$CRLF"
        $xmlPayload += "  <VmMoRef>$($vmImportObject.MoRef)</VmMoRef>$CRLF"
        $xmlPayload += "  <Vdc href=""$($OrgVDCObject.Href)""/>$CRLF"
        $xmlPayload += "  <Catalog href=""$($CatalogObject.href)""/>$CRLF"
        $xmlPayload += "</ImportVmAsVAppTemplateParams>"

    } else {
        # Note URI endpoints are CASE-SENSATIVE - make sure they match excatly with what is listed in the API documentation
        $ImportURI = "$($ProviderVC.href)/importVmAsVApp"
        [string] $ContentType = "application/vnd.vmware.admin.importVmAsVAppParams+xml"

        # Construct the XML
        $CRLF = [Environment]::NewLine
        $xmlPayload  = "<?xml version=""1.0"" encoding=""UTF-8""?>$CRLF"
        $xmlPayload += "<ImportVmAsVAppParams xmlns=""http://www.vmware.com/vcloud/extension/v1.5"" name=""$($vmImportObject.name)"" sourceMove=""true"">$CRLF"
        $xmlPayload += "  <VmMoRef>$($vmImportObject.MoRef)</VmMoRef>$CRLF"
        $xmlPayload += "  <Vdc href=""$($OrgVDCObject.Href)""/>$CRLF"
        $xmlPayload += "</ImportVmAsVAppParams>"
    }

    # Set the parameters for the API Call
    [Hashtable] $ImportRequestParameters = @{
        URI = $ImportURI
        Method = "Post"
        APIVersion = 33
        APIType = "Legacy"
        CustomContentType = $ContentType
        Data = $xmlPayload
    }
    [xml] (Invoke-CICloudAPIRequest @ImportRequestParameters).RawData
}
