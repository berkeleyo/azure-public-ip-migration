param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Use-Subscription {
  param([string]$SubscriptionId)
  if ($SubscriptionId) { az account set --subscription $SubscriptionId | Out-Null }
}

function Write-CsvSafe {
  param(
    [Parameter(Mandatory)] [string] $Path,
    [Parameter(Mandatory)] [object[]] $Rows
  )
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $Rows | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
}

function Get-Json {
  param([string[]]$Args)
  $json = az @Args --only-show-errors -o json | ConvertFrom-Json
  return $json
}

function Log {
  param([string]$Message)
  $ts = (Get-Date).ToString('s')
  Write-Host "[$ts] $Message"
}
