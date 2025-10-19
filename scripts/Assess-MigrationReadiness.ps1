<# 
.SYNOPSIS
  Assess readiness of enriched PIPs (NSG, scenario flags) and emit a lightweight HTML report.

.PARAMETER InCsv
  Enriched CSV from Enrich script.

.PARAMETER Report
  Output report path (default: out/readiness.html)
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$InCsv,
  [string]$Report = "out/readiness.html"
)

$ErrorActionPreference = 'Stop'
$rows = Import-Csv -Path $InCsv

$report = @()
foreach ($r in $rows) {
  if ($r.SubscriptionId) { Set-AzContext -SubscriptionId $r.SubscriptionId | Out-Null }

  $status = "Ready"
  $notes  = @()

  switch ($r.AttachedType) {
    "VMNic" {
      # Try to find an NSG on NIC or subnet
      $pip = Get-AzPublicIpAddress -Name $r.PublicIpName -ResourceGroupName $r.ResourceGroupName
      $ipconfId = $pip.IpConfiguration.Id
      $nicName  = ($ipconfId -split "/")[8]
      $nicRg    = ($ipconfId -split "/")[4]

      $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $nicRg
      $hasNsg = $false
      if ($nic.NetworkSecurityGroup) { $hasNsg = $true }
      else {
        $subnetId = $nic.IpConfigurations[0].Subnet.Id
        $vnetRg = ($subnetId -split "/")[4]
        $vnetNm = ($subnetId -split "/")[8]
        $subNm  = ($subnetId -split "/")[-1]
        $vnet = Get-AzVirtualNetwork -Name $vnetNm -ResourceGroupName $vnetRg
        $sn = $vnet.Subnets | Where-Object Name -eq $subNm
        if ($sn.NetworkSecurityGroup) { $hasNsg = $true }
      }
      if (-not $hasNsg) { $status = "Blocked"; $notes += "No NSG on NIC/subnet (required for Standard PIP inbound)." }
      if ($r.Allocation -ne "Static") { $status = "Blocked"; $notes += "Allocation must be Static to keep IP." }
    }
    "LoadBalancer" {
      $status = "Manual"
      $notes += "LB upgrade required; LB and PIP SKUs must match."
    }
    "Gateway" {
      $status = "Manual"
      $notes += "Use Gateway 'Migrate' experience (brief downtime)."
    }
    Default { }
  }

  $report += [pscustomobject]@{
    SubscriptionId    = $r.SubscriptionId
    ResourceGroupName = $r.ResourceGroupName
    PublicIpName      = $r.PublicIpName
    AttachedType      = $r.AttachedType
    Allocation        = $r.Allocation
    SKU               = $r.SKU
    Status            = $status
    Notes             = ($notes -join "; ")
  }
}

New-Item -ItemType Directory -Force -Path (Split-Path $Report) | Out-Null
$head = "<html><body><h2>Public IP Readiness</h2><table border=1 cellpadding=4><tr><th>Sub</th><th>RG</th><th>PIP</th><th>Type</th><th>Alloc</th><th>SKU</th><th>Status</th><th>Notes</th></tr>"
$rowsHtml = ($report | ForEach-Object {
  "<tr><td>$($_.SubscriptionId)</td><td>$($_.ResourceGroupName)</td><td>$($_.PublicIpName)</td><td>$($_.AttachedType)</td><td>$($_.Allocation)</td><td>$($_.SKU)</td><td>$($_.Status)</td><td>$($_.Notes)</td></tr>"
}) -join "`n"
$tail = "</table></body></html>"
Set-Content -Encoding UTF8 -Path $Report -Value ($head + $rowsHtml + $tail)

Write-Host "Wrote $Report"
