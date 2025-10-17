#!/usr/bin/env pwsh
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $PublicIpId,
  [bool] $WhatIf = $true
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/utils.ps1"

$pip = Get-Json @('resource','show','--ids', $PublicIpId)
if (-not $pip) { throw "Public IP not found: $PublicIpId" }
if ($pip.sku.name -ne 'Basic') { throw "Not a Basic SKU PIP: $($pip.sku.name)" }

$rg  = $pip.resourceGroup
$loc = $pip.location
$name= $pip.name
$newName = "$name-std"

Log "Creating Standard PIP $newName in $rg/$loc (static)"
$createArgs = @('network','public-ip','create','-g',$rg,'-n',$newName,'-l',$loc,'--sku','Standard','--allocation-method','Static')
if ($WhatIf) { Log "WHATIF: az $($createArgs -join ' ')" } else { Get-Json $createArgs | Out-Null }

$ipcfgId = $pip.ipConfiguration.id
if (-not $ipcfgId) {
  Log "No attachment found. Skipping rebind."
}
elseif ($ipcfgId -match '/networkInterfaces/') {
  Log "Rebinding NIC to Standard IP"
  $nicId = ($ipcfgId -split '/ipConfigurations/')[0]
  $nic   = Get-Json @('resource','show','--ids',$nicId)
  $ipcfgName = ($ipcfgId -split '/ipConfigurations/')[1]
  if ($WhatIf) {
    Log "WHATIF: az network nic ip-config update -g $rg --nic-name $($nic.name) -n $ipcfgName --public-ip-address $newName"
  } else {
    Get-Json @('network','nic','ip-config','update','-g',$rg,'--nic-name',$nic.name,'-n',$ipcfgName,'--public-ip-address',$newName) | Out-Null
  }
}
elseif ($ipcfgId -match '/loadBalancers/') { throw "Attached to Load Balancer. Upgrade LB to Standard first." }
elseif ($ipcfgId -match '/applicationGateways/') { throw "Attached to Application Gateway. Swap frontend public IP via AppGW update." }
elseif ($ipcfgId -match '/virtualNetworkGateways/') { throw "VPN Gateway detected. Use Microsoft migration workflow." }

Log "Deleting old Basic PIP $name"
$delArgs = @('network','public-ip','delete','-g',$rg,'-n',$name)
if ($WhatIf) { Log "WHATIF: az $($delArgs -join ' ')" } else { az @delArgs | Out-Null }

Log "Done. New Standard IP: $newName"
