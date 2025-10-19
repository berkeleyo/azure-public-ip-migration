# Migration Guide

This guide outlines end-to-end steps to move **Basic** Azure Public IPs to **Standard**.

## 1 ) Discover
Run `scripts/Discover-BasicPublicIPs.ps1` to produce `out/discovery.csv`.

## 2 ) Enrich
Run `scripts/Enrich-PublicIP-Attachments.ps1` to add `AttachedType/AttachedTo/AttachedResource`, outputting `out/enriched.csv`.

## 3 ) Assess
Run `scripts/Assess-MigrationReadiness.ps1` to validate:
- NSG present on NIC or subnet (required for Standard’s secure-by-default).
- If **Load Balancer**, plan LB + PIP SKU alignment and upgrade sequence.
- If **VPN/ER Gateway**, plan the Gateway *Migrate* flow (brief downtime).

## 4 ) Plan batches
Prefer small batches per subscription/RG. Communicate maintenance windows and rollback.

## 5 ) Migrate (dry-run first)
`Migrate-PublicIP.ps1 -InCsv out/enriched.csv -Scope VM -WhatIf`

## 6 ) Validate
Post-change checks:
- Service reachability (synthetic tests, app health)
- NSG rules allow intended traffic
- Review logs; archive `out/` artifacts

## 7 ) Rollback
- **VM NIC path**: re-run with recovery CSV (if generated) or reverse the NIC/PIP association.
- **LB/Gateway**: follow Azure’s rollback steps or restore previous infra state (Bicep/ARM/Terraform snapshot).

---

## Scenario runbooks

### A) VM NIC public IP
1. Ensure allocation is **Static**  
2. **Disassociate** from NIC  
3. Change SKU ➜ **Standard**  
4. **Reassociate** and confirm NSG rules

### B) Load Balancer
Upgrade the **LB** and its **frontend PIP(s)** together; SKUs must match.

### C) VPN/ExpressRoute Gateway
Use the **Gateway ➜ Configuration ➜ Migrate** flow (expect brief downtime).
