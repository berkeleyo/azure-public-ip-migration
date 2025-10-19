# Enumerate Basic SKU Public IPs
Get-AzSubscription | ForEach-Object {
    Set-AzContext -Subscription $_.Id | Out-Null
    Get-AzPublicIpAddress | Where-Object {$_.Sku.Name -eq 'Basic'} |
    Select-Object Name, ResourceGroupName, Location, IpAddress
}
