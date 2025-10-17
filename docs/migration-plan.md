# Migration Plan & Rollback

Prepare
- Freeze window approved
- Confirm NSG rules (Standard PIP is secure-by-default)
- Health checks ready

Execute (per IP)
1. Create Standard static IP in same RG/region
2. Rebind (NIC → IP config, or LB/AppGW flow)
3. Validate
4. Remove Basic IP

Rollback
- Reattach original Basic IP (if still present) or reverse change

Special cases
- Load Balancer: upgrade LB to Standard, then swap frontend IP
- VPN Gateway: use Microsoft migration wizard (short downtime)
