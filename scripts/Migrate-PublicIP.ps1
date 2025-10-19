<# 
.SYNOPSIS
  Upgrade VM NIC-attached Basic PIPs to Standard (keeps IP). Skips LB/Gateway.

.PARAMETER InCsv
  Enriched CSV from Enrich script.

.PARAMETER Scope
  VM | LB | Gateway | All   (default: VM; LB/Gateway are skipped with guidance)

.PARAMETER Filter
  Semi-colon filters e.g. "SubscriptionId=...;ResourceGroupName=rg1;PublicIpName=pip-01"

.PARAMETER WhatIf
  Dry-run (default: on if -WhatIf specified)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory)][string]$InCsv,
  [ValidateSet("VM","LB","Gateway","All")][string]$Scope = "VM",
  [string]$Filter,
  [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$rows = Import-Csv -Path $InCsv

function Match-Filter($row, $filter) {
  if (-not $filter) { return $true }
  $pairs = $filter -split ';' | Where-Object { $_ -match '=' }
  foreach ($p in $pairs) {
    $k,$v = $p -split '=',2
    if ($row.$k -ne $v) { return $false }
  }
  return $true
}

foreach ($r in $rows) {
  if (-not (Match-Filter $r $Filter)) { continue }
  if ($Scope -eq "VM" -and $r.AttachedType -ne "VMNic") { continue }
  if ($Scope -ne "VM" -and $Scope -ne "All") { continue } # we only automate VM here

  if ($r.SubscriptionId) { Set-AzContext -SubscriptionId $r.SubscriptionId | Out-Null }

  $pip = Get-AzPublicIpAddress -Name $r.PublicIpName -ResourceGroupName $r.ResourceGroupName -ErrorAction Stop

  if ($pip.Sku.Name -eq "Standard") { Write-Host "Already Standard: $($r.PublicIpName)"; continue }
  if ($pip.PublicIpAllocationMethod -ne "Static") { Write-Warning "Skip (Dynamic): $($r.PublicIpName)"; continue }
  if (-not $pip.IpConfiguration -or $pip.IpConfiguration.Id -notmatch "/networkInterfaces/") {
    Write-Warning "Skip (Not VM NIC): $($r.PublicIpName)"; continue
  }

  # Find NIC + ipconfig
  $ipconfId = $pip.IpConfiguration.Id
  $nicRg  = ($ipconfId -split "/")[4]
  $nicNm  = ($ipconfId -split "/")[8]
  $ipName = ($ipconfId -split "/")[-1]
  $nic = Get-AzNetworkInterface -ResourceGroupName $nicRg -Name $nicNm

  $msg = "Upgrade $($r.PublicIpName) (RG: $($r.ResourceGroupName)) to Standard and reattach to NIC $nicNm/$ipName"
  if ($PSCmdlet.ShouldProcess($r.PublicIpName, $msg)) {

    # 1) Disassociate
    $ipcfg = $nic.IpConfigurations | Where-Object Name -eq $ipName
    $ipcfg.PublicIpAddress = $null
    Set-AzNetworkInterface -NetworkInterface $nic | Out-Null

    # 2) Upgrade
    $pip.Sku.Name = "Standard"
    Set-AzPublicIpAddress -PublicIpAddress $pip | Out-Null

    # 3) Reassociate
    $ipcfg.PublicIpAddress = $pip
    Set-AzNetworkInterface -NetworkInterface $nic | Out-Null

    Write-Host "Upgraded: $($r.PublicIpName) -> Standard (IP kept: $($pip.IpAddress))"
  }
}
