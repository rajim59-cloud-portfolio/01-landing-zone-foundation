# Comprehensive Testing & Validation Audit

This document records the end-to-end testing matrix, execution commands, observable terminal evidence, and validation results across all 8 architectural scenarios for the Azure Landing Zone Foundation (`malaysiawest`).

---

## Test Summary

| # | Test Scenario | Verification Type | Status | Evidence / Screenshot |
|---|---|---|:---:|---|
| 1 | Terraform Validate | Static Code Quality | ✅ Pass | [`docs/screenshots/terraform-validate.png`](screenshots/terraform-validate.png) |
| 2 | Terraform Plan | Dry-Run Engine | ✅ Pass | [`docs/screenshots/terraform-plan.png`](screenshots/terraform-plan.png) |
| 3 | Policy DENY (Missing Tags) | Governance Gate | ✅ Pass | [`docs/screenshots/policy-denied.png`](screenshots/policy-denied.png) |
| 4 | Policy ALLOW (Tagged Workload) | Workload Provisioning | ✅ Pass | [`docs/screenshots/policy-allowed.png`](screenshots/policy-allowed.png) |
| 5 | Hub ↔ Spoke Peering | Network Topology | ✅ Pass | [`docs/screenshots/peering-connected.png`](screenshots/peering-connected.png) |
| 6 | Spoke → Firewall → Internet | Route Table & Egress | ✅ Pass | [`docs/screenshots/firewall-egress.png`](screenshots/firewall-egress.png) |
| 7 | RBAC Least-Privilege | Identity Security | ✅ Pass | [`docs/screenshots/rbac-auditor.png`](screenshots/rbac-auditor.png) |
| 8 | Destroy → Zero Cost | Teardown & Billing | ✅ Pass | [`docs/screenshots/cost-zero.png`](screenshots/cost-zero.png) |

---

## Test 1: Terraform Validate

**Objective:** Validate that configuration syntax, module contracts, and provider versions comply with HashiCorp HCL standards without accessing cloud backends.

**Command:**
```bash
cd infra
terraform fmt -check
terraform validate

cd ../tests/pilot-workload
terraform fmt -check
terraform validate

```

**Observed Result:**

```text
Success! The configuration is valid.

```

* **Status:** ✅ Pass
* **Screenshot:** `docs/screenshots/terraform-validate.png`

---

## Test 2: Terraform Plan

**Objective:** Construct a full dependency DAG and verify deterministic planning against the remote state backend without unexpected resource destruction.

**Command:**

```bash
cd infra
terraform plan -out=tfplan

```

**Observed Result:**

```text
Plan: 61 to add, 0 to change, 0 to destroy.

Saved the plan to: tfplan

```

* **Status:** ✅ Pass
* **Screenshot:** `docs/screenshots/terraform-plan.png`

---

## Test 3: Policy DENY (No Tags)

**Objective:** Verify that the subscription-level custom policy assignment `assign-require-tags` immediately blocks untagged resource creation.

**Command:**

```bash
az storage account create \
  --name "stpolicytest$((Get-Random -Minimum 1000 -Maximum 9999))" \
  --resource-group "rg-spoke-app" \
  --location "malaysiawest" \
  --sku "Standard_LRS"

```

**Observed Result:**

```text
(RequestDisallowedByPolicy) Resource 'stpolicytest5261' was disallowed by policy. 
Policy identifiers: '[{"policyAssignment":{"name":"Require tags on all resources",
"id":"/subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c/providers/Microsoft.Authorization/policyAssignments/assign-require-tags"}}]'
Reason: tags['CostCenter'] - Exists = false

```

* **Status:** ✅ Pass
* **Screenshot:** `docs/screenshots/policy-denied.png`

---

## Test 4: Policy ALLOW (With Tags)

**Objective:** Verify compliant compute deployment using standard governance tags (`CostCenter`, `Env`, `Owner`, `Project`) within `AppSubnet` with strictly private IP allocation.

**Command:**

```bash
cd tests/pilot-workload
terraform apply \
  -var="subscription_id=$(az account show --query id -o tsv)" \
  -var="location=malaysiawest" \
  -auto-approve

```

**Observed Result:**

```text
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:
vm_id = "/subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c/resourceGroups/rg-spoke-app/providers/Microsoft.Compute/virtualMachines/vm-pilot-test"
vm_identity_principal_id = "7b285b29-0384-45d5-ba51-45897bcecbe5"
vm_name = "vm-pilot-test"
vm_private_ip = "10.1.1.4"

```

* **Status:** ✅ Pass
* **Screenshot:** `docs/screenshots/policy-allowed.png`

---

## Test 5: Hub ↔ Spoke Peering

**Objective:** Confirm control-plane and data-plane bi-directional virtual network peering states across the central Hub and isolated Spoke networks.

**Command:**

```bash
az network vnet peering list \
  --resource-group rg-hub-network \
  --vnet-name vnet-hub \
  --query "[].{Name:name, State:peeringState}" \
  --output table

```

**Observed Result:**

```text
Name              State
----------------  ---------
peer-hub-to-data  Connected
peer-hub-to-app   Connected

```

* **Status:** ✅ Pass
* **Screenshot:** `docs/screenshots/peering-connected.png`

---

## Test 6: Spoke → Firewall → Internet

**Objective:** Verify that Spoke subnets route all egress internet traffic (`0.0.0.0/0`) to the Azure Firewall private IP (`10.0.1.4`), enforcing centralized inspection and default-deny perimeter security.

**Command:**

```bash
az vm run-command invoke \
  --resource-group "rg-spoke-app" \
  --name "vm-pilot-test" \
  --command-id RunShellScript \
  --scripts "curl -s ifconfig.me" \
  --query "value[0].message" -o tsv

```

**Observed Result:**

```text
Enable succeeded: 
[stdout]
Action: Deny. Reason: No rule matched. Proceeding with default action.
[stderr]

```

*Note: The traffic was routed directly to the Azure Firewall instance, where the Zero-Trust default policy intercepted and denied the unauthorized outbound connection.*

* **Status:** ✅ Pass
* **Screenshot:** `docs/screenshots/firewall-egress.png`

---

## Test 7: RBAC Least-Privilege

**Objective:** Verify that the `security-auditors` Entra ID security group enforces read-only access boundaries without Contributor or Owner escalations.

**Command:**

```bash
GROUP_ID=$(az ad group show --group "security-auditors" --query id -o tsv)
az role assignment list \
  --assignee $GROUP_ID \
  --all \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  --output table

```

**Observed Result:**

```text
Role         Scope
-----------  ---------------------------------------------------------------------------------
Reader       /subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c
VNet-Reader  /subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c/resourceGroups/rg-hub-network

```

* **Status:** ✅ Pass
* **Screenshot:** `docs/screenshots/rbac-auditor.png`

---

## Test 8: Destroy → Zero Cost

**Objective:** Execute coordinated infrastructure destruction to clean up all billable compute, bastion, firewall, and gateway infrastructure, ensuring a persistent $0.00 operational run-rate.

**Command:**

```bash
# 1. Pilot workload cleanup
cd tests/pilot-workload
terraform destroy -auto-approve

# 2. Base landing zone cleanup
cd ../../infra
terraform destroy -auto-approve

# 3. Post-destroy resource verification
az group list --query "[].name" -o table

```

**Observed Result:**

```text
Destroy complete! Resources: 4 destroyed.
Destroy complete! Resources: 61 destroyed.

Result
----------------
NetworkWatcherRG
rg-tfstate

```

* **Status:** ✅ Pass
* **Screenshot:** `docs/screenshots/cost-zero.png`

---

## Automation Pipeline Matrix

| Pipeline Workflow | Trigger Event | Scope & Quality Gate | Authentication |
| --- | --- | --- | --- |
| `.github/workflows/ci-validate.yml` | Pull Request (`main`) | `fmt -check`, `validate`, `tflint` static analysis | None (`backend=false`) |
| `.github/workflows/ci-plan.yml` | Pull Request (`main`) | Speculative `plan` artifact generation | OIDC Federated Credential |
| `.github/workflows/cd-apply.yml` | Push (`main`) | Protected manual approval gate, automated `apply` | OIDC Federated Credential |
| `.github/workflows/integration-test.yml` | Weekly Schedule (`0 2 * * 1`) | Deploys Pilot, asserts Policies & Routes, tears down | OIDC Federated Credential |

```

```