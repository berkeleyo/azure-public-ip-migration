# Enumerate Basic SKU Public IPs across all subscriptions
$subs = az account list --query "[].id" -o tsv
foreach ($s in $subs) {
  az account set --subscription $s
  az network public-ip list --query "[?sku.name=='Basic'].{Name:name,RG:resourceGroup,IP:ipAddress}" -o table
}
