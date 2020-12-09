function Set-CISystemSettings(){
  <#
  .SYNOPSIS
  Adjusts the System Settings for the currently connected Cloud Director Service.

  .DESCRIPTION
  Adjusts the System Settings for the currently connected Cloud Director Service. Requires System Administrator rights.

  .PARAMETER activityLogDisplayDays
  Activity log history to show to users in days. The value must be a whole number between 0 and 365. If you set the value to zero, all days are displayed.

  .PARAMETER activityLogKeepDays
  Activity log history to keep on the system. The value must be a whole number between 0 and 3600. If you set the value to zero, old logs are never deleted.

  .PARAMETER showStackTraces
  If $true the stack traces will be shown in the Activity Log. Only system administrators can view the debug information.

  .PARAMETER ipReservationTimeoutSeconds
  IP address release timeout setting. The value must be a whole number between 0 and 2592000. Specifies how long to keep released IP addresses on hold before making them available for allocation again. This is typically set to 2 hours to allow old entries to expire from client ARP tables. IP addresses on hold are not shown in 'IP Allocations'.

  .PARAMETER allowOverlappingExtNets
  This setting allows you to add external networks that run on the same network segment. You should only enable this setting if you are using non-VLAN-based methods to isolate your external networks

  .PARAMETER allowFipsModeForEdgeGateways
  This settings allows you to enable FIPS mode on edge gateways. FIPS mode is only available on NSX versions 6.3 and above CAUTION - All NSX components must be version 6.3 or above for FIPS mode to work

  .PARAMETER subInterfacesEnabled
  This setting controls if the NSX Edge subinterfaces are enabled.

  .PARAMETER advancedNetworkingEnabled
  This setting controls if the Advanced Networking services should be enabled on the NSX Edges

  .PARAMETER advancedNetworkingDfwApiUrl
  The URI for the Distributed Firewall API for the Advanced Networking services

  .PARAMETER advancedNetworkingDfwUiUrl
   The URI for the Distributed Firewall UI for the Advanced Networking services

  .PARAMETER advancedNetworkingGatewayApiUrl
   The URI for the Distributed Firewall Gateway API for the Advanced Networking services

  .PARAMETER advancedNetworkingGatewayUiUrl
  The URI for the Distributed Firewall Gateway UI for the Advanced Networking services

  .PARAMETER syslogServerSettings
  A PSObject containing syslogServerIp1 and syslogServerIp2 properties. The IP addresses will be used as the Syslog settings for the installation.

  .PARAMETER sessionTimeoutMinutes
  Amount of time the VMware Cloud Director application remains active without user interaction. The value must be a whole number between 1 and 3600.

  .PARAMETER absoluteSessionTimeoutMinutes
  Maximum amount of time the VMware Cloud Director application remains active. The value must be a whole number between 1 and 43200.

  .PARAMETER transferSessionTimeoutSeconds
  Amount of time to wait before failing a paused or canceled upload task, for example, to upload media or upload a vApp template. This timeout does not affect upload tasks that are in progress. The value must be a whole number between 2700 and 2592000.

  .PARAMETER hostCheckDelayInSeconds
  How often VMware Cloud Director checks whether its ESX/ESXi hosts are accessible or inaccessible. The value must be a whole number between 1 and 3600.

  .PARAMETER hostCheckTimeoutSeconds
  The amount of time to wait before marking a host as hung. The value must be a whole number between 1 and 3600.

  .PARAMETER quarantineEnabled
  If $true enables the upload quarantine

  .PARAMETER quarantineResponseTimeoutSeconds
  Upload quarantine with timeout

  .PARAMETER verifyVcCertificates
  If $true the certificate for the vCenter Server will be validated

  .PARAMETER verifyVsmCertificates
  If $true the certificate for the NSX Manager will be validated

  .PARAMETER maxVdcQuota
  Maximum number of Organization VDCs

  .PARAMETER loginNameOnly
  ????

  .PARAMETER elasticAllocationPool
  Make Allocation pool Organization VDCs elastic. Enable the option to enable elastic allocation pool, making all allocation pool organization virtual data centers (VDCs) elastic. Before deselecting this option, ensure that all virtual machines for each Organization VDC have been migrated to a single cluster.

  .PARAMETER prePopDefaultName
  Enable VMware Cloud Director configuration to provide default names for new vApps.

  .PARAMETER vmDiscoveryEnabled
  By default, each Organization VDC automatically discovers vCenter Server VMs created in any VDC backing resource pool. Clear to disable this option for all VDCs in the system.

  .PARAMETER installationId
  The vCloud Director Installation Id

  .PARAMETER installationId
  VMWare Remote Console Version

  .PARAMETER RunningPerUser
  Number of resource-intensive operations running per user. 0 = No limit

  .PARAMETER RunningPerOrg
  Number of resource-intensive operations to be queued per user (in addition to running). 0 = No limit

  .PARAMETER QueuedOperationsPerUser
  Number of resource-intensive operations running per organization. 0 = No limit

  .PARAMETER QueuedOperationsPerOrg
  Number of resource-intensive operations to be queued per organization (in addition to running). 0 = No limit

  .PARAMETER MaxActiveSddcProxyQuota
  A quota which defines the maximum number of active SDDC Proxies (CPOM).

  .PARAMETER MaxActiveSddcProxyPerUserQuota
  A quota which defines the maximum number of active SDDC Proxies per user (CPOM).

  .PARAMETER SddcProxiedHostConnectionTimeoutSeconds
  The timeout in seconds for CPOM SDDC Proxy (CPOM).

  .PARAMETER AllowInsecureSddcProxying
  If $true allow insecure SDDC Proxy. (CPOM)

  .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-04-08
    VERSION: 1.0
    #>
  Param(
    [Parameter(Mandatory=$False)]
        [ValidateRange(0, 365)] [int] $activityLogDisplayDays,
        [ValidateRange(0, 3600)] [int] $activityLogKeepDays,
        [bool] $showStackTraces,
        [ValidateRange(0, 2592000)] [int] $ipReservationTimeoutSeconds,
        [bool] $allowOverlappingExtNets,
        [bool] $allowFipsModeForEdgeGateways,
        [bool] $subInterfacesEnabled,
        [bool] $advancedNetworkingEnabled,
        [string] $advancedNetworkingDfwApiUrl,
        [string] $advancedNetworkingDfwUiUrl,
        [string] $advancedNetworkingGatewayApiUrl,
        [string] $advancedNetworkingGatewayUiUrl,
        [PSObject] $syslogServerSettings,
        [ValidateRange(0, 3600)] [int] $sessionTimeoutMinutes,
        [ValidateRange(0, 43200)] [int] $absoluteSessionTimeoutMinutes,
        [ValidateRange(2700, 2592000)] [int] $transferSessionTimeoutSeconds,
        [ValidateRange(1, 3600)] [int] $hostCheckDelayInSeconds,
        [int] $hostCheckTimeoutSeconds,
        [bool] $quarantineEnabled,
        [ValidateRange(2700, 2592000)] [int] $quarantineResponseTimeoutSeconds,
        [bool] $verifyVcCertificates,
        [bool] $verifyVsmCertificates,
        [ValidateRange(0, 2592000)] [int] $maxVdcQuota,
        [bool] $loginNameOnly,
        [bool] $elasticAllocationPool,
        [bool] $prePopDefaultName,
        [ValidateRange(1, 99)] [int] $installationId,
        [bool] $vmDiscoveryEnabled,
        [int] $vmrcVersion,
        [ValidateRange(0, 99999)] [int] $RunningPerUser,
        [ValidateRange(0, 99999)] [int] $RunningPerOrg,
        [ValidateRange(0, 99999)] [int] $QueuedOperationsPerUser,
        [ValidateRange(0, 99999)] [int] $QueuedOperationsPerOrg,
        [ValidateRange(0, 500)] [int] $MaxActiveSddcProxyQuota,
        [ValidateRange(0, 500)] [int] $MaxActiveSddcProxyPerUserQuota,
        [ValidateRange(0, 2592000)] [int] $SddcProxiedHostConnectionTimeoutSeconds,
        [bool] $AllowInsecureSddcProxying
  )
  # Retrieve the General Settings for the currently connected installation
  [Hashtable] $RequestParameters = @{
    URI = "$($global:DefaultCIServers.ServiceUri)admin/extension/settings/general"
    Method = "Get"
    APIVersion = 33
    APIType = "Legacy"
    LegacyAPIDataType = "JSON"
  }
  $GeneralSettings = (Invoke-CICloudAPIRequest @RequestParameters).JSONData

  # Retreive the Operational Limit Settings
  $RequestParameters.URI = "$($global:DefaultCIServers.ServiceUri)admin/extension/settings/operationLimitsSettings"
  $OperationLimitSettings = (Invoke-CICloudAPIRequest @RequestParameters).JSONData

  # Retreive the CPOM Settings
  $RequestParameters.URI = "$($global:DefaultCIServers.ServiceUri)admin/extension/settings/cpom"
  $CPOMSettings = (Invoke-CICloudAPIRequest @RequestParameters).JSONData

  [bool] $SettingsChange = $False # A variable to track if a setting has actually changed
  [bool] $OpLimitSettingsChange = $False
  [bool] $CPOMSettingsChange = $False

  # Now update any parameters that have been provided
  #region: Activity Log
  if($PSBoundParameters.ContainsKey('activityLogDisplayDays')){
    $GeneralSettings.activityLogDisplayDays = $activityLogDisplayDays
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('activityLogKeepDays')){
    $GeneralSettings.activityLogKeepDays = $activityLogKeepDays
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('showStackTraces')){
    $GeneralSettings.showStackTraces = $showStackTraces
    $SettingsChange = $true
  }
  #endregion
  #region: Networking
  if($PSBoundParameters.ContainsKey('ipReservationTimeoutSeconds')){
    $GeneralSettings.ipReservationTimeoutSeconds = $ipReservationTimeoutSeconds
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('allowOverlappingExtNets')){
    $GeneralSettings.allowOverlappingExtNets = $allowOverlappingExtNets
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('allowFipsModeForEdgeGateways')){
    $GeneralSettings.allowFipsModeForEdgeGateways = $allowFipsModeForEdgeGateways
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('subInterfacesEnabled')){
    $GeneralSettings.subInterfacesEnabled = $subInterfacesEnabled
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('advancedNetworkingEnabled')){
    $GeneralSettings.advancedNetworkingEnabled = $advancedNetworkingEnabled
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('advancedNetworkingDfwApiUrl')){
    $GeneralSettings.advancedNetworkingDfwApiUrl = $advancedNetworkingDfwApiUrl
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('advancedNetworkingDfwUiUrl')){
    $GeneralSettings.advancedNetworkingDfwUiUrl = $advancedNetworkingDfwUiUrl
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('advancedNetworkingGatewayApiUrl')){
    $GeneralSettings.advancedNetworkingGatewayApiUrl = $advancedNetworkingGatewayApiUrl
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('advancedNetworkingGatewayUiUrl')){
    $GeneralSettings.advancedNetworkingGatewayUiUrl = $advancedNetworkingGatewayUiUrl
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('syslogServerSettings')){
    $GeneralSettings.syslogServerSettings.syslogServerIp1 = $syslogServerSettings.syslogServerIp1
    $GeneralSettings.syslogServerSettings.syslogServerIp2 = $syslogServerSettings.syslogServerIp2
    $SettingsChange = $true
  }
  #endregion
  #region: Timeouts
  if($PSBoundParameters.ContainsKey('sessionTimeoutMinutes')){
    $GeneralSettings.sessionTimeoutMinutes = $sessionTimeoutMinutes
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('absoluteSessionTimeoutMinutes')){
    $GeneralSettings.absoluteSessionTimeoutMinutes = $absoluteSessionTimeoutMinutes
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('transferSessionTimeoutSeconds')){
    $GeneralSettings.transferSessionTimeoutSeconds = $transferSessionTimeoutSeconds
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('hostCheckDelayInSeconds')){
    $GeneralSettings.hostCheckDelayInSeconds = $hostCheckDelayInSeconds
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('hostCheckTimeoutSeconds')){
    $GeneralSettings.hostCheckTimeoutSeconds = $hostCheckTimeoutSeconds
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('quarantineEnabled')){
    $GeneralSettings.quarantineEnabled = $quarantineEnabled
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('quarantineResponseTimeoutSeconds')){
    $GeneralSettings.quarantineResponseTimeoutSeconds = $quarantineResponseTimeoutSeconds
    $SettingsChange = $true
  }
  #endregion
  #region: Certificates
  if($PSBoundParameters.ContainsKey('verifyVcCertificates')){
    $GeneralSettings.verifyVcCertificates = $verifyVcCertificates
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('verifyVsmCertificates')){
    $GeneralSettings.verifyVsmCertificates = $verifyVsmCertificates
    $SettingsChange = $true
  }
  #endregion

  #region: OrganizationLimits
  if($PSBoundParameters.ContainsKey('maxVdcQuota')){
    $GeneralSettings.maxVdcQuota = $maxVdcQuota
    $SettingsChange = $true
  }
  #endregion

  #region: Other
  if($PSBoundParameters.ContainsKey('loginNameOnly')){
    $GeneralSettings.loginNameOnly = $loginNameOnly
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('elasticAllocationPool')){
    $GeneralSettings.elasticAllocationPool = $elasticAllocationPool
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('vmDiscoveryEnabled')){
    $GeneralSettings.vmDiscoveryEnabled = $vmDiscoveryEnabled
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('installationId')){
    $GeneralSettings.installationId = $installationId
    $SettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('vmrcVersion')){
    $GeneralSettings.vmrcVersion = $vmrcVersion
    $SettingsChange = $true
  }
  #endregion
  # Check if any settings were actually changed (as the cmdlet allows for no parameters)
  if($SettingsChange){
    [Hashtable] $UpdateParameters = @{
      URI = "$($global:DefaultCIServers.ServiceUri)admin/extension/settings/general"
      Method = "Put"
      APIVersion = 33
      APIType = "Legacy"
      LegacyAPIDataType = "JSON"
      Data = (ConvertTo-JSON $GeneralSettings -Depth 100)
    }
    # Make the API call to update the settings
    (Invoke-CICloudAPIRequest @UpdateParameters).JSONData
  }

  #region: OperationLimits
  if($PSBoundParameters.ContainsKey('RunningPerUser')){
    $OperationLimitSettings.RunningPerUser = $RunningPerUser
    $OpLimitSettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('RunningPerOrg')){
    $OperationLimitSettings.RunningPerOrg = $RunningPerOrg
    $OpLimitSettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('QueuedOperationsPerUser')){
    $OperationLimitSettings.QueuedOperationsPerUser = $QueuedOperationsPerUser
    $OpLimitSettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('QueuedOperationsPerOrg')){
    $OperationLimitSettings.QueuedOperationsPerOrg = $QueuedOperationsPerOrg
    $OpLimitSettingsChange = $true
  }
  # Update the settings if something was changed
  if($OpLimitSettingsChange){
    [Hashtable] $UpdateParameters = @{
      URI = "$($global:DefaultCIServers.ServiceUri)admin/extension/settings/operationLimitsSettings"
      Method = "Put"
      APIVersion = 33
      APIType = "Legacy"
      LegacyAPIDataType = "JSON"
      Data = (ConvertTo-JSON $OperationLimitSettings -Depth 100)
    }
    # Make the API call to update the settings
    (Invoke-CICloudAPIRequest @UpdateParameters).JSONData
  }
  #endregion

  #region: CPOM
  if($PSBoundParameters.ContainsKey('MaxActiveSddcProxyQuota')){
    $CPOMSettings.MaxActiveSddcProxyQuota = $MaxActiveSddcProxyQuota
    $CPOMSettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('MaxActiveSddcProxyPerUserQuota')){
    $CPOMSettings.MaxActiveSddcProxyPerUserQuota = $MaxActiveSddcProxyPerUserQuota
    $CPOMSettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('SddcProxiedHostConnectionTimeoutSeconds')){
    $CPOMSettings.SddcProxiedHostConnectionTimeoutSeconds = $SddcProxiedHostConnectionTimeoutSeconds
    $CPOMSettingsChange = $true
  }
  if($PSBoundParameters.ContainsKey('AllowInsecureSddcProxying')){
    $CPOMSettings.AllowInsecureSddcProxying = $AllowInsecureSddcProxying
    $CPOMSettingsChange = $true
  }

  if($CPOMSettingsChange){
    [Hashtable] $UpdateParameters = @{
      URI = "$($global:DefaultCIServers.ServiceUri)admin/extension/settings/cpom"
      Method = "Put"
      APIVersion = 33
      APIType = "Legacy"
      LegacyAPIDataType = "JSON"
      Data = (ConvertTo-JSON $CPOMSettings -Depth 100)
    }
    # Make the API call to update the settings
    (Invoke-CICloudAPIRequest @UpdateParameters).JSONData
  }
  #endregion
}