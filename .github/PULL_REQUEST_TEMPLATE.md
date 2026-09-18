## PR Summary

<!-- Provide a clear, concise summary of the architectural changes or module updates introduced in this pull request -->

---

## Type of Change

- [ ] **Feature:** New architecture module or foundational resource
- [ ] **Governance:** Azure Policy, Management Group, or RBAC role definition
- [ ] **Networking:** Route table (UDR), peering, DNS, or firewall rule update
- [ ] **FinOps:** Budget alert threshold, SKU adjustment, or lifecycle automation
- [ ] **Automation:** Windows PowerShell (`.ps1`) or CI/CD workflow update
- [ ] **Documentation:** Architecture, ADR, cost estimation, or test audit record
- [ ] **Bug Fix / Refactor:** Syntax fix or module refactoring

---

## Architectural & Governance Checklist

### 1. Code Quality & Formatting
- [ ] Ran `terraform fmt -recursive` across all root and module directories
- [ ] Ran `terraform validate` and confirmed: `Success! The configuration is valid.`
- [ ] Ran `terraform plan` and verified no unintended resource destruction

### 2. Azure Policy & Landing Zone Guardrails
- [ ] Verified mandatory governance tags are present: `CostCenter`, `Env`, `Owner`, `Project`
- [ ] Executed local pre-flight check: `.\scripts\validate-tags.ps1`
- [ ] Verified deployment target complies with approved regions (`malaysiawest` or `southeastasia`)
- [ ] Verified zero unauthorized Public IP addresses (`deny-public-ip` compliance)
- [ ] Verified all egress routes route `0.0.0.0/0` through the central Firewall (`10.0.1.4`)

### 3. Identity, Security & DNS
- [ ] Verified least-privilege Entra ID security group mappings (`network-admins`, `cloud-engineers`, `security-auditors`)
- [ ] Private DNS resolution configured via centralized Hub DNS zones (`privatelink.*`)
- [ ] Defender for Cloud CSPM Free tier (`CloudPosture`) preserved without paid licensing drift

### 4. Secret Management & FinOps Hygiene
- [ ] Verified no plaintext secrets, service principal keys, or `.tfvars` files are committed
- [ ] Added `local.tfvars` to `.gitignore`
- [ ] Verified workload or platform budget alerts remain within cost constraints
- [ ] Tested or confirmed clean teardown path via `.\scripts\destroy.ps1`

---

## Verification Evidence

<!-- Attach CLI execution logs, terraform plan summaries, policy test outputs, or screenshot references -->

### CLI / Test Execution Log
```text
<Paste here or output plan script summary, terraform validate,>

```

### Screenshot References (if applicable)

* Evidence linked under `docs/screenshots/`: 

---

## Impact on Downstream Workloads (Project 2+)

* [ ] No impact on downstream consumers
* [ ] Updated exported outputs in `outputs.tf` (documented in `HANDOVER.md`)
* [ ] Requires downstream remote state schema update

---

## Related Issue / Work Item

Closes #
