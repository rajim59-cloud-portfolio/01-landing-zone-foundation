# Cost Estimation

This document provides a monthly cost estimate for the landing zone and strategies to minimize actual spend.

---

## 1. Monthly Cost Estimate (Always-On)

| Resource | SKU | Unit Price | Est. Monthly |
|---|---|---|---|
| Azure Firewall | Basic | ~$0.40/hour | ~$290 |
| Azure Bastion | Basic | ~$0.19/hour | ~$140 |
| Log Analytics Workspace | Pay-as-you-go | ~$2.76/GB | ~$5–10 |
| VNet Peering | Data transfer | ~$0.01/GB | ~$1–2 |
| Public IP (Firewall) | Standard | ~$0.005/hour | ~$4 |
| **Total** | | | **~$440** |

> Prices are based on East US pay-as-you-go rates as of 2026. Actual costs vary by region.

---

## 2. Cost Reduction Strategy

### Primary Strategy: Daily Destroy

Run `./scripts/destroy.sh` at the end of each work session. This destroys all resources except the Terraform state storage account.

| Scenario | Monthly Cost |
|---|---|
| Always-on | ~$440 |
| 7 active days/month | ~$100 |
| 3 active days/month | ~$45 |

### Secondary Strategies

| Strategy | Saving | How |
|---|---|---|
| Use Basic SKUs | ~$600/month | Already chosen (Firewall Basic, Bastion Basic) |
| Log Analytics daily cap | ~$5–10 | Set 1 GB/day cap |
| No GatewaySubnet VPN | ~$100+/month | Reserved subnet only, no actual VPN |
| Delete unused resource groups | Variable | Automated via destroy script |

---

## 3. Cost Guardrails

- **Budget:** $50/month alert set at 50% ($25), 80% ($40), and 100% ($50).
- **Tag enforcement:** All resources must carry `CostCenter`, `Env`, and `Owner` tags (Azure Policy).
- **Monthly review:** Export cost data via Cost Management and review in `docs/screenshots/`.

---

## 4. Production Considerations

In a production environment:
- Firewall **Standard** SKU (~$900/month) would be used for L7 inspection.
- Bastion **Standard** SKU would support more concurrent sessions.
- Reserved instances would reduce compute costs by 30–40%.

These are intentionally excluded from this portfolio project to keep costs near zero.