# Scripts Overview

**Discover-BasicPublicIPs.ps1**  
Enumerates Basic PIPs across subscriptions:  
`SubscriptionId, ResourceGroupName, PublicIpName, IP, Location, DNS, Allocation, SKU`.

**Enrich-PublicIP-Attachments.ps1**  
Resolves attachment details:  
`AttachedType (VMNic|LoadBalancer|Gateway|Unassigned), AttachedTo, AttachedResource`.

**Assess-MigrationReadiness.ps1**  
Validates NSG presence and LB/Gateway constraints; produces `out/readiness.html`.

**Migrate-PublicIP.ps1**  
Guarded migrations for **VM NIC-attached** PIPs.  
Supports `-WhatIf`, filtering, logs, and recovery hints.
