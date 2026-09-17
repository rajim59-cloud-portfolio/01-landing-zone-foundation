# Module: monitoring

Central Log Analytics workspace, diagnostic settings, budget alerts, and a KQL-based alert for firewall deny events.

## Resources

| Resource | Purpose |
|----------|---------|
| `azurerm_log_analytics_workspace` | Central log store (30-day retention, 1 GB/day cap) |
| Diagnostic settings (×4) | Firewall, Bastion, Spoke-App VNet, Spoke-Data VNet |
| `azurerm_monitor_action_group` | Email alerts |
| `azurerm_consumption_budget_subscription` | Budget alerts at 50/80/100% |
| `azurerm_monitor_scheduled_query_rules_alert_v2` | Firewall denied > 100 in 15 min |

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `location` | — | Azure region |
| `tags` | — | Resource tags |
| `retention_days` | 30 | Log retention |
| `daily_quota_gb` | 1 | Daily ingestion cap (cost guard) |
| `budget_amount_usd` | 50 | Monthly budget |
| `alert_email` | — | Alert recipient |
| `firewall_resource_id` | — | Firewall resource ID |
| `bastion_resource_id` | — | Bastion resource ID |
| `spoke_app_vnet_id` | — | Spoke-App VNet ID |
| `spoke_data_vnet_id` | — | Spoke-Data VNet ID |

## Outputs

| Name | Description |
|------|-------------|
| `log_analytics_workspace_id` | LAW resource ID |
| `log_analytics_workspace_name` | LAW name |
| `monitoring_resource_group_name` | Monitoring RG name |

## Security notes

- `daily_quota_gb = 1` prevents log ingestion cost spikes.
- Budget alert at **forecasted 100%** stops runaway spend.
- Diagnostic settings capture firewall deny logs for audit.