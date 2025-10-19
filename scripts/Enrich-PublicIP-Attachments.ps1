<# 
.SYNOPSIS
  Enrich discovery output with attachment metadata.

.PARAMETER InCsv
  Input CSV from Discover script.

.PARAMETER OutCsv
  Output enriched CSV (default: out/enriched.csv)
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$InCsv,
  [string]$OutCsv = "out/enriched.csv"
)

$ErrorActionPreference = 'Stop'
$items = Import-Csv -Path $InCsv
$enriched = @()

foreach ($row in $items) {
  $sub = $row.SubscriptionId
  if ($sub) { Set-AzContext -SubscriptionId $sub | Out-Null }

  $pip = Get-AzPublicIpAddress -Name $row.PublicIpName -ResourceGroupName $row.ResourceGroupName -ErrorAction Stop

  $attachType  = "Unassigned"
  $attachedTo  = ""
  $attachedRes = ""

  if ($pip.IpConfiguration) {
    $id = $pip.IpConfiguration.Id

    if ($id -match "/networkInterfaces/([^/]+)/ipConfigurations/([^/]+)$") {
      $attachType  = "VMNic"
      $attachedTo  = $Matches[1]
      $attachedRes = $Matches[2]
    }
    elseif ($id -match "/loadBalancers/([^/]+)/frontendIPConfigurations/([^/]+)$") {
      $attachType  = "LoadBalancer"
      $attachedTo  = $Matches[1]
      $attachedRes = $Matches[2]
    }
    elseif ($id -match "/gateways/|/virtualNetworkGateways/") {
      $attachType  = "Gateway"
      $attachedTo  = "Gateway"
      $attachedRes = $id
    }
  }

  $enriched += [pscustomobject]@{
    SubscriptionId        = $row.SubscriptionId
    ResourceGroupName     = $row.ResourceGroupName
    PublicIpName          = $row.PublicIpName
    IP                    = $pip.IpAddress
    Location              = $row.Location
    DNS                   = $row.DNS
    Allocation            = $pip.PublicIpAllocationMethod
    SKU                   = $pip.Sku.Name
    AttachedType          = $attachType
    AttachedTo            = $attachedTo
    AttachedResource      = $attachedRes
  }
}

New-Item -ItemType Directory -Force -Path (Split-Path $OutCsv) | Out-Null
$enriched | Export-Csv -NoTypeInformation -Path $OutCsv
Write-Host "Wrote $OutCsv with $($enriched.Count) rows."
