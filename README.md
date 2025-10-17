[![powershell-ci](https://github.com/berkeleyo/azure-public-ip-migration/actions/workflows/powershell-ci.yml/badge.svg)](https://github.com/berkeleyo/azure-public-ip-migration/actions/workflows/powershell-ci.yml)

# Azure Public IP Migration (Basic ➜ Standard)

Find every Basic SKU Public IP across your subscriptions and migrate them to Standard before retirement.

## Quick start
bash scripts/bootstrap-macos.sh
az login
make discover
make enrich
make migrate PIP_ID="/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/publicIPAddresses/<name>" WHATIF=true

## Requirements
- macOS 12+
- Xcode CLT (xcode-select --install)
- Homebrew
- Azure CLI (az) and PowerShell 7 (pwsh)

## Outputs
- out/basic-public-ips.csv
- out/basic-public-ips.enriched.csv

## Notes
- Load Balancers: upgrade LB to Standard before swapping to a Standard PIP.
- VPN Gateway: use Microsoft’s migration workflow.
- NIC rebind is usually brief; LB/AppGW varies.

## Scripts
- scripts/bootstrap-macos.sh
- scripts/discover-basic-pips.ps1
- scripts/enrich-pips.ps1
- scripts/migrate-pip.ps1
- scripts/utils.ps1

