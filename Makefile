SHELL := /bin/bash
PWSH := pwsh
OUT := out

.DEFAULT_GOAL := help

$(OUT):
mkdir -p $(OUT)

help:
@echo "Targets: setup, discover, enrich, migrate, clean"

setup: $(OUT)
@echo "Run: bash scripts/bootstrap-macos.sh"

discover: $(OUT)
$(PWSH) -File scripts/discover-basic-pips.ps1 -OutFile $(OUT)/basic-public-ips.csv

enrich: discover
$(PWSH) -File scripts/enrich-pips.ps1 -InFile $(OUT)/basic-public-ips.csv -OutFile $(OUT)/basic-public-ips.enriched.csv

migrate:
@test -n "$(PIP_ID)" || (echo "PIP_ID is required" && exit 1)
$(PWSH) -File scripts/migrate-pip.ps1 -PublicIpId "$(PIP_ID)" -WhatIf $(WHATIF)

clean:
rm -rf $(OUT)
