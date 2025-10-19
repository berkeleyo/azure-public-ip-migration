# Azure Public IP Migration (Basic ➜ Standard)
 [![ps-ci](https://github.com/berkeleyo/azure-public-ip-migration/actions/workflows/powershell-ci.yml/badge.svg)](https://github.com/berkeleyo/azure-public-ip-migration/actions/workflows/powershell-ci.yml)


Discover, assess, and migrate **Azure Public IPs** from **Basic** to **Standard** at scale — safely and reproducibly.

> **Why this exists**  
> Microsoft is retiring Basic SKU Public IPs on **September 30, 2025**. Standard SKU adds secure-by-default NSG behavior, zones, and better resiliency.  
> This project helps you **find** Basic IPs, **understand** what they’re attached to (VM NIC, Load Balancer, Gateway, or Unassigned), and **migrate** them with guardrails.

---

## Quick Start

```bash
# 0) Prereqs
# - PowerShell 7+, Az modules
# - Reader on discovery subs; Contributor for migration

# 1) Login & (optionally) set context
Connect-AzAccount
# Select-AzSubscription -SubscriptionId "<SUB-ID>"

# 2) Discover Basic PIPs across your subs
pwsh ./scripts/Discover-BasicPublicIPs.ps1 -OutCsv out/discovery.csv

# 3) Enrich with attachment info (VM NIC / LB / Gateway / Unassigned)
pwsh ./scripts/Enrich-PublicIP-Attachments.ps1 -InCsv out/discovery.csv -OutCsv out/enriched.csv

# 4) (Optional) Preflight report
pwsh ./scripts/Assess-MigrationReadiness.ps1 -InCsv out/enriched.csv -Report out/readiness.html

# 5) Migrate VM NIC-attached PIPs (dry-run first)
pwsh ./scripts/Migrate-PublicIP.ps1 -InCsv out/enriched.csv -Scope VM -WhatIf
