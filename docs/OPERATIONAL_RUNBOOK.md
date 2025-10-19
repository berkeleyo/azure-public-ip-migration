# Operational Runbook (Change Window)

## Purpose
Step-by-step day-of instructions: approvals, comms, execution, validation, rollback.

## Approvals & Comms
- CAB approval: ___  
- Stakeholders: App owners, Networking, SecOps  
- Maintenance window: ___ UTC  
- Rollback window: ___ UTC  

## Pre-checks (T-24 h)
- Latest `out/enriched.csv` and readiness report signed off  
- Export backups of NSG/VM/LB definitions  
- Test plan agreed and owners on-call  

## Change (per batch)
1. Announce start  
2. Dry-run: `Migrate-PublicIP.ps1 -InCsv ... -Scope VM -Filter "<batch>" -WhatIf`  
3. Execute: remove `-WhatIf` on approval  
4. Monitor `migration.log` and Azure Activity Log  
5. Validate service health (synthetics + app checks)  
6. Record results and artifacts  

## Rollback
- VM path: re-run with recovery CSV or reverse NIC/PIP association  
- LB/Gateway: follow Azure guidance or restore previous infra state  

## Post-checks
- Security review (NSG/ASG as intended)  
- Observability sanity  
- Close change & circulate summary  
