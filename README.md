# VMware.Cloud.Director.Community
Yet another community PowerShell modules to expose REST API functions for VMware Cloud Director 10.X functions as PowerShell cmdlets.

This module fills several functional gaps for Cloud Director in the current implementation of PowerCLI particularly with the newer /cloudapi endpoint.

This module was created from a collection of cmdlets and there is some significant "clean-up" required particularly with the Compute Policy cmdlets which changes a lot between Cloud Director 10/10.1/10.2.

**Please Note**: This is a community supported module. It is not provided by, affiliated with or supported by VMware.

## Project Owner
Adrian Begg (@AdrianBegg)

## Credit
1. The Branding cmdlets were refactored based on the original work of Jon Waite. The original implementation is available from https://raw.githubusercontent.com/jondwaite/vcd-h5-themes/master/vcd-h5-themes.psm1
2. The ConvertTo-HashTable function was developed by Adam Bertram (https://4sysops.com/archives/convert-json-to-a-powershell-hash-table/)

## Tested Versions
* PowerShell : 7.1
* VMware Cloud Director 10.2

## Functional Coverage
### Access Control
* Get-CIRights : Get a list of Cloud Director Rights visible to the logged in user.
* Get-CIRightsBundle : Returns a collection of Cloud Director Rights Bundles.
* Get-CIRightsCategory : Get a list of Cloud Director Rights Categories visible to the logged in user.
* Get-CIRolev2 : Gets the Roles for the currently connected Cloud Director Organization (using CloudAPI)
* New-CIRightsBundle : Creates a new Rights Bundle in the currently connected Cloud Director instance.
* New-CIRole : Creates a new role on the currently connected Cloud Director Organization.
* New-CISAMLGroup : Adds a new SAML Group to the Cloud Director RBAC and assigns the group the provided Role
* New-CIUser : Creates a new local user in the connected vCloud Director instance.
* Remove-CIRole : Removes a Role from the currently connected Cloud Director Organization.
* Set-CIRightsBundleRights : Adjusts (replaces) the Rights on an existing Cloud Director Rights Bundle to the collection of Rights provided.
* Set-CIRoleRights : Adjusts (replaces) the Rights on an existing Cloud Director Role to the collection of Rights provided.

### Administration
* Get-CIAuditTrail : Returns the Cloud Director Audit Trail
* Set-CIEmailSettings : Sets the Email Settings on the currently connected Cloud Director Service
* Set-CIPasswordPolicy : Adjusts the Local Account Password Policy for Cloud Director Service
* Set-CISystemSettings : Adjusts the System Settings for the currently connected Cloud Director Service.

### Branding
* Get-CIBrandingIcon : Downloads the currently defined branding icon for a Cloud Director instance.
* Get-CIBrandingPolicy : Gets the currently defined branding settings for a Cloud Director instance.
* Get-CIBrandingThemes : Gets a list of any themes defined in the Cloud Director installation.
* New-CIBrandingTheme : Creates a new (custom) theme for Cloud Director.
* Publish-CIBrandingIcon : Uploads a graphic file (PNG format) to be used as the Cloud Director icon
* Publish-CIBrandingLogo : Uploads a graphic file (PNG format) to be used as the Cloud Director Logo
* Remove-CIBrandingTheme : Removes a (custom) theme for Cloud Director
* Set-CIBrandingPolicy : Sets the currently defined branding settings for a Cloud Director instance.
* Set-CIBrandingTheme : Uploads a new (or replaces existing) CSS theme for Cloud Director.

### Compute PVDC Policies **(Deprecated)**
* Get-CIPVDCComputePolicy : Get list of Provider Virtual Datacenter (pVDC) compute policies.**(Deprecated)**
* New-CIPVDCComputePolicy : Creates a new VM Placement Policy (VDC Compute Policy) on a Provider VDC. **(Deprecated)**
* Remove-CIPVDCComputePolicy : Removes a Provider Virtual Datacenter (pVDC) compute policies from the currently connected installation. **(Deprecated)**

### Compute VDC Policies
* Get-CIVDCComputePolicy : Get list of Organization vDC (OrgVDC) Compute policies **(Deprecated)**
* Get-CIVMGroups : Get list of vCenter VM Groups registered against a Provider Virtual Datacenter (pVDC). These can be used for PVDC Compute Policy. **(Deprecated)**
* New-CIVMSizingPolicy : Creates a new Organizational Virtual Datacenter Compute Policy for Sizing (VM Sizing Policy).

### External networks
* Get-CIExternalNetwork : Returns a collection of Cloud Director External Networks
* New-CIExternalNetworkSpecification : Creates a new External Network Specification on a Cloud Director External Network
* Remove-CIExternalNetworkSpecification : Removes an existing Network Specification from a Cloud Director External Network
* Set-CIExternalNetwork : Updates the basic parameters of a specific Cloud Director external network.

### Logical VM Groups
* Get-CILogicalVMGroup : Get list of logical VM groups
* New-CILogicalVMGroup : Creates a logical VM group in Cloud Director which can be used for VM Placement Policies

### NSX-T Resources
* Get-CINSXTManager : Returns the NSX-T Managers that are registered with Cloud Director
* Get-CINSXTNetworkPools : Returns the NSX-T Network Pools for the Cloud Director

### Provider VDC
* Get-CIProviderVC : Returns vCenter servers configured as Provider VCDs vCenter
* Get-CIPVDC : Get list of Provider Virtual Datacenter (pVDC)
* Import-CIProviderVCVM : Imports Virtual Machines from the Resource vCenter into Cloud Director
* New-CIPVDC : Creates a new Provider Virtual Datacenter (PVDC) in the currently connected Cloud Director

### Site
* Get-CISite : Returns the Local Cloud Director site details
* Set-CISite : Adjusts the Site Name for the currently connected Director Director Site

All of the cmdlets in the module **should** have well described PowerShell help available (some work is needed here). For detailed help including examples please use `Get-help <cmdlet> -Detailed` (e.g. `Get-help Get-CIRights -Detailed`).

### Change Log
**v0.1.4 - Minor fix (8th January 2021)**
* Adjusted check in private function Invoke-CICloudAPIRequest to check "AllUsers" scope (instead of User scope) for the InvalidCertificateAction for better behavior in automation (pipelines)

**v0.1 - Initial release (9th December 2020)**
* Initial public release