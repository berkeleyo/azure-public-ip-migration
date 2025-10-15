
# Enumerate Basic SKU Public IPs across all subscriptions and export to CSV
$out = @()
$subs = az account list --query "[].id" -o tsv
foreach ($s in $subs) {
  az account set --subscription $s
  $pips = az network public-ip list --query "[?sku.name=='Basic']" -o json | ConvertFrom-Json
  foreach ($p in $pips) {
    $out += [pscustomobject]@{
      Subscription = $s
      RG = $p.resourceGroup
      Name = $p.name
      IP = $p.ipAddress
      Location = $p.location
      Allocation = $p.publicIPAllocationMethod
      AttachedTo = $p.ipConfiguration?.id
    }
  }
}
$out | Export-Csv ./basic-pips.csv -NoTypeInformation
