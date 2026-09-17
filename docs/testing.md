# Testing

This document records the test cases, how to run them, and their results.

---

## Test Summary

| # | Test | Type | Status |
|---|---|---|---|
| 1 | Terraform Validate | Static | ⏳ Pending |
| 2 | Terraform Plan | Static | ⏳ Pending |
| 3 | Policy DENY (no tags) | Integration | ⏳ Pending |
| 4 | Policy ALLOW (with tags) | Integration | ⏳ Pending |
| 5 | Hub ↔ Spoke Peering | Integration | ⏳ Pending |
| 6 | Spoke → Firewall → Internet | Integration | ⏳ Pending |
| 7 | RBAC Least-Privilege | Integration | ⏳ Pending |
| 8 | Destroy → Zero Cost | Integration | ⏳ Pending |

> Update status to ✅ Pass or ❌ Fail as tests are executed.

---

## Test 1: Terraform Validate

**Command:**

```bash
cd infra
terraform fmt -check
terraform validate

```

Expected: No formatting errors, no validation errors.

Screenshot: `docs/screenshots/terraform-validate.png`

---

## Test 2: Terraform Plan

**Command:**

```bash
cd infra
terraform plan -out=tfplan

```

Expected: Plan completes with expected resource count. No unexpected destroys.

Screenshot: `docs/screenshots/terraform-plan.png`

---

## Test 3: Policy DENY (No Tags)

What it tests: Azure Policy should block resource creation without required tags.

**Command:**

```bash
cd tests/pilot-workload
terraform init
terraform apply \
  -var="subscription_id=$(az account show --query id -o tsv)" \
  -var="location=malaysiawest" \
  -target=azurerm_network_interface.pilot_vm_nic

```

Expected: Deployment fails with `RequestDisallowedByPolicy`.

Screenshot: `docs/screenshots/policy-denied.png`

---

## Test 4: Policy ALLOW (With Tags)

What it tests: Resource creation succeeds when all required tags are present.

**Command:**

```bash
cd tests/pilot-workload
terraform apply \
  -var="subscription_id=$(az account show --query id -o tsv)" \
  -var="location=malaysiawest" \
  -auto-approve

```

Expected: Deployment succeeds.

Screenshot: `docs/screenshots/policy-allowed.png`

---

## Test 5: Hub ↔ Spoke Peering

What it tests: VNet peering is established and connected.

**Command:**

```bash
az network vnet peering list \
  --resource-group rg-hub-network \
  --vnet-name vnet-hub \
  --query "[].{Name:name, State:peeringState}" \
  --output table

```

Expected: All peerings show Connected.

Screenshot: `docs/screenshots/peering-connected.png`

---

## Test 6: Spoke → Firewall → Internet

What it tests: Outbound traffic from Spoke routes through the Firewall.

**Command (from a VM in Spoke-App):**

```bash
curl -s ifconfig.me

```

Expected: Output shows the Firewall's public IP, not the VM's.

Screenshot: `docs/screenshots/firewall-egress.png`

---

## Test 7: RBAC Least-Privilege

What it tests: The security-auditors group has only Reader access.

**Command:**

```bash
az role assignment list \
  --assignee security-auditors@domain.com \
  --all \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  --output table

```

Expected: Only Reader role assignments.

Screenshot: `docs/screenshots/rbac-auditor.png`

---

## Test 8: Destroy → Zero Cost

What it tests: terraform destroy removes all billable resources.

**Command:**

```bash
cd infra
terraform destroy -auto-approve

```

Expected: All resources destroyed. Azure Cost Management shows $0.00 next day.

Screenshot: `docs/screenshots/cost-zero.png`

---

## Automation

Tests 1–2 run on every PR via `.github/workflows/ci-validate.yml` and `ci-plan.yml`.

Tests 3–8 run weekly via `.github/workflows/integration-test.yml` using a pilot workload.
