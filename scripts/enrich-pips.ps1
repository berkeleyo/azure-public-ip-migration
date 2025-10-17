#!/usr/bin/env pwsh
param(
  [Parameter(Mandatory)] [string] $InFile,
  [string] $OutFile = 'out/basic-public-ips.enriched.csv'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Csv $InFile | ForEach-Object {
  $row = $_
  $attachedId = $row.AttachedTo
  $type = 'None'
  $hint = ''
  if ($attachedId) {
    switch -Regex ($attachedId) {
      '/providers/Microsoft.Network/networkInterfaces/' { $type='NIC' ; break }
      '/providers/Microsoft.Network/loadBalancers/'    { $type='LoadBalancer' ; break }
      '/providers/Microsoft.Network/applicationGateways/' { $type='AppGateway' ; break }
      '/providers/Microsoft.Network/virtualNetworkGateways/' { $type='VpnGateway' ; break }
      default { $type='Unknown' }
    }
  }
  [pscustomobject]@{
    Subscription  = $row.Subscription
    ResourceGroup = $row.ResourceGroup
    PublicIpName  = $row.PublicIpName
    PublicIpId    = $row.PublicIpId
    IPAddress     = $row.IPAddress
    Location      = $row.Location
    Allocation    = $row.Allocation
    DnsLabel      = $row.DnsLabel
    AttachedType  = $type
    AttachedTo    = $attachedId
    Hints         = $hint
  }
} | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8

Write-Host "Enriched CSV -> $OutFile"
