#!/usr/bin/env pwsh
param(
  [string] $OutFile = 'out/basic-public-ips.csv',
  [string[]] $Subscriptions = @()
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/utils.ps1"

$subs = if ($Subscriptions.Count -gt 0) { $Subscriptions } else { (Get-Json @('account','list','--query','[?isDefault || state==`"Enabled`"].id')) }

$rows = @()
foreach ($sub in $subs) {
  Log "Scanning subscription $sub ..."
  Use-Subscription $sub
  $pips = Get-Json @('network','public-ip','list','--query','[?sku.name==`"Basic`" ]')
  foreach ($pip in $pips) {
    $rows += [pscustomobject]@{
      Subscription   = $sub
      ResourceGroup  = $pip.resourceGroup
      PublicIpName   = $pip.name
      PublicIpId     = $pip.id
      IPAddress      = $pip.ipAddress
      Location       = $pip.location
      Allocation     = $pip.publicIPAllocationMethod
      DnsLabel       = $pip.dnsSettings.domainNameLabel
      AttachedTo     = $pip.ipConfiguration.id
      Tags           = ($pip.tags | ConvertTo-Json -Compress)
    }
  }
}

Write-CsvSafe -Path $OutFile -Rows $rows
Log "Wrote $($rows.Count) Basic IP(s) to $OutFile"
