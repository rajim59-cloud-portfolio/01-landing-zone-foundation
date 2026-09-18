# Module: defender

Enables Microsoft Defender for Cloud — Foundational CSPM (Free tier), plus optional paid tiers.

## What is enabled

| Feature | Tier | Cost |
|---------|------|------|
| Foundational CSPM | Free | $0 |
| Security Contact | — | $0 |

## Optional (off by default)

| Feature | Cost (approx.) |
|---------|----------------|
| Defender for Servers (P1) | ~$15/server/month |
| Defender CSPM | ~$5/billable resource/month |

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `alert_email` | string | — | Email for security alerts |
| `enable_servers_pricing` | bool | `false` | Enable Defender for Servers |
| `enable_cspm` | bool | `false` | Enable Defender CSPM (paid) |