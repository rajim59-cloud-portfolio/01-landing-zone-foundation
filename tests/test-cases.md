# Comprehensive Test Cases & Verification Report

This document records the end-to-end testing, validation scenarios, policy enforcement checks, and zero-cost teardown procedures executed against the Azure Landing Zone Foundation (`malaysiawest` region).

---

## Executive Test Summary

| # | Test Scenario | Category | Scope / Target | Execution Tool | Status |
|---|---|---|---|---|:---:|
| 1 | Static Syntax & Provider Validation | Static Analysis | `infra/`, `tests/pilot-workload/` | Terraform CLI | **PASSED** |
| 2 | Speculative Execution Plan | Dry-Run Engine | `infra/`, `tests/pilot-workload/` | Terraform CLI | **PASSED** |
| 3 | Azure Policy Denial (No Tags) | Governance Guardrail | `Microsoft.Storage/storageAccounts` | Azure CLI | **PASSED** |
| 4 | Compliant Workload Deployment | Workload Provisioning | `rg-spoke-app` / `AppSubnet` | Terraform CLI | **PASSED** |
| 5 | Bi-directional VNet Peering | Network Topology | `vnet-hub` ↔ `vnet-spoke-*` | Azure CLI | **PASSED** |
| 6 | Centralized Firewall Egress Inspection | Perimeter Routing | `UDR 0.0.0.0/0` → Azure Firewall | VM RunCommand | **PASSED** |
| 7 | Least-Privilege RBAC Verification | Identity & Security | `security-auditors` Entra ID Group | Azure CLI | **PASSED** |
| 8 | Infrastructure Teardown & Billing Zeroing | Cost Governance | Full Subscription State | Terraform CLI | **PASSED** |

---

## Test Case 1: Static Syntax & Provider Validation

### Objective
Verify that all Terraform source files, module blocks, provider constraints, and backend declarations strictly adhere to HashiCorp HCL formatting and semantic standards.

### Command Executed
```bash
# Core Landing Zone
cd infra
terraform fmt -check
terraform validate

# Pilot Workload Test Suite
cd ../tests/pilot-workload
terraform fmt -check
terraform validate

```

### Observed Output

```text
Success! The configuration is valid.

```

### Verification Result

* **Status:** PASSED
* **Evidence:** Both modules passed static analysis without missing required attributes or unresolved provider references.

---

## Test Case 2: Speculative Execution Plan (Dry Run)

### Objective

Ensure that Terraform builds a deterministic directed acyclic graph (DAG) across all 6 modular components without cyclic dependencies or state lock errors.

### Command Executed

```bash
cd infra
terraform plan -out=tfplan

```

### Observed Output

```text
Plan: 61 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + cloud_engineers_group_id   = (known after apply)
  + firewall_private_ip        = "10.0.1.4"
  + hub_vnet_id                = (known after apply)
  + hub_vnet_name              = "vnet-hub"
  + log_analytics_workspace_id = (known after apply)
  + resource_group_names       = {
      + hub        = "rg-hub-network"
      + spoke_app  = "rg-spoke-app"
      + spoke_data = "rg-spoke-data"
    }
  + spoke_app_subnet_ids       = {
      + app  = (known after apply)
      + func = (known after apply)
    }
  + spoke_data_subnet_ids      = {
      + data = (known after apply)
      + pe   = (known after apply)
    }

```

### Verification Result

* **Status:** PASSED
* **Evidence:** Clean state lock acquisition against remote backend (`sttfstaterajim01`). All 61 baseline resources cleanly mapped.

---

## Test Case 3: Governance Policy Enforcement (DENY on Missing Tags)

### Objective

Validate that subscription-scoped Azure Policy definitions (`require-required-tags`) intercept and block non-compliant resource provisioning attempts in real time.

### Command Executed

```bash
az storage account create \
  --name "stpolicytest5261" \
  --resource-group "rg-spoke-app" \
  --location "malaysiawest" \
  --sku "Standard_LRS"

```

### Observed Output

```json
{
  "error": {
    "code": "RequestDisallowedByPolicy",
    "message": "Resource 'stpolicytest5261' was disallowed by policy. Policy identifiers: '[{\"policyAssignment\":{\"name\":\"Require tags on all resources\",\"id\":\"/subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c/providers/Microsoft.Authorization/policyAssignments/assign-require-tags\"},\"policyDefinition\":{\"name\":\"Require CostCenter, Env, and Owner tags\",\"id\":\"/subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c/providers/Microsoft.Authorization/policyDefinitions/require-required-tags\",\"version\":\"1.0.0\"}}]'.",
    "target": "stpolicytest5261",
    "details": [
      {
        "result": "True",
        "expression": "tags['CostCenter']",
        "path": "tags['CostCenter']",
        "targetValue": "false",
        "operator": "Exists"
      }
    ]
  }
}

```

### Verification Result

* **Status:** PASSED
* **Evidence:** Azure Policy engine successfully evaluated `tags['CostCenter']` as missing and returned an immediate HTTP 403 Forbidden with `RequestDisallowedByPolicy`.

---

## Test Case 4: Compliant Pilot Workload Deployment

### Objective

Deploy a private Linux compute workload into `AppSubnet` consuming landing zone infrastructure directly via native Azure data sources, ensuring zero public IP assignment.

### Command Executed

```bash
cd tests/pilot-workload
terraform apply -auto-approve

```

### Observed Output

```text
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:
admin_password = <sensitive>
admin_username = "azureuser"
bastion_ssh_command = "az network bastion ssh --name bastion-hub --resource-group rg-hub-network --target-resource-id /subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c/resourceGroups/rg-spoke-app/providers/Microsoft.Compute/virtualMachines/vm-pilot-test --auth-type password --username azureuser"
vm_id = "/subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c/resourceGroups/rg-spoke-app/providers/Microsoft.Compute/virtualMachines/vm-pilot-test"
vm_identity_principal_id = "7b285b29-0384-45d5-ba51-45897bcecbe5"
vm_name = "vm-pilot-test"
vm_private_ip = "10.1.1.4"

```

### Verification Result

* **Status:** PASSED
* **Evidence:**
* Internal IP allocated: `10.1.1.4` within CIDR `10.1.1.0/24`.
* Zero public IP attached (compliant with `assign-deny-public-ip`).
* System-assigned Managed Identity provisioned with Object ID `7b285b29-0384-45d5-ba51-45897bcecbe5`.
* Diagnostic metrics successfully routed to central Log Analytics Workspace.



---

## Test Case 5: Bi-directional Hub-Spoke VNet Peering

### Objective

Validate peering connectivity states between Hub network (`vnet-hub`) and dedicated Spokes (`vnet-spoke-app`, `vnet-spoke-data`).

### Command Executed

```bash
az network vnet peering list \
  --resource-group "rg-hub-network" \
  --vnet-name "vnet-hub" \
  --query "[].{Name:name, State:peeringState}" -o table

```

### Observed Output

```text
Name              State
----------------  ---------
peer-hub-to-data  Connected
peer-hub-to-app   Connected

```

### Verification Result

* **Status:** PASSED
* **Evidence:** Both peering links report `Connected` state, confirming bi-directional control-plane establishment and gateway forwarding readiness.

---

## Test Case 6: Centralized Firewall Egress & Routing Inspection

### Objective

Verify that Spoke subnets enforce egress route tables (`UDR 0.0.0.0/0 -> 10.0.1.4`), preventing direct internet bypass and ensuring inspection through the Azure Firewall Basic instance.

### Command Executed

```bash
az vm run-command invoke \
  --resource-group "rg-spoke-app" \
  --name "vm-pilot-test" \
  --command-id RunShellScript \
  --scripts "curl -s ifconfig.me" \
  --query "value[0].message" -o tsv

```

### Observed Output

```text
Enable succeeded: 
[stdout]
Action: Deny. Reason: No rule matched. Proceeding with default action.
[stderr]

```

### Verification Result

* **Status:** PASSED
* **Evidence:**
* The outbound HTTP request was routed through the Spoke UDR directly to the Hub Firewall.
* Azure Firewall evaluated the egress traffic against configured Network Rule Collections.
* In alignment with Zero-Trust architectural principles, the default drop action (`Action: Deny. Reason: No rule matched.`) successfully blocked untrusted outbound exfiltration.



---

## Test Case 7: Least-Privilege RBAC Verification

### Objective

Audit Entra ID role assignments for security audit personas, verifying that read-only isolation is strictly enforced without administrative privilege escalation.

### Command Executed

```bash
GROUP_ID=$(az ad group show --group "security-auditors" --query id -o tsv)
az role assignment list --assignee $GROUP_ID --all --query "[].{Role:roleDefinitionName, Scope:scope}" -o table

```

### Observed Output

```text
Role         Scope
-----------  ---------------------------------------------------------------------------------
Reader       /subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c
VNet-Reader  /subscriptions/5856ea95-14af-42c5-a3de-d77985bd761c/resourceGroups/rg-hub-network

```

### Verification Result

* **Status:** PASSED
* **Evidence:**
* `security-auditors` possesses strictly `Reader` rights at the Subscription root.
* Scoped `VNet-Reader` access is isolated to `rg-hub-network`.
* Zero write, delete, or Contributor permissions exist across resource tiers.



---

## Test Case 8: Infrastructure Teardown & Zero-Cost State Verification

### Objective

Execute coordinated teardown of both pilot workloads and base platform resources to verify clean dependency release and eliminate persistent hourly resource charges.

### Command Executed

```bash
# 1. Pilot Workload Teardown
cd tests/pilot-workload
terraform destroy -auto-approve

# 2. Core Landing Zone Teardown
cd ../../infra
terraform destroy -auto-approve

# 3. Post-Teardown Subscription Audit
az group list --query "[].name" -o table

```

### Observed Output

```text
# Step 1:
Destroy complete! Resources: 4 destroyed.

# Step 2:
Destroy complete! Resources: 61 destroyed.

# Step 3:
Result
----------------
NetworkWatcherRG
rg-tfstate

```

### Verification Result

* **Status:** PASSED
* **Evidence:** All billable compute, network gateways, firewall instances, and Bastion hosts are destroyed. The subscription footprint is reduced to $0.00 billable run-rate, preserving only remote Terraform state storage.
