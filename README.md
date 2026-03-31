# PowerVS outbound internet access hub on IBM Cloud with Terraform

This Terraform stack builds the core egress infrastructure for one or more PowerVS workspaces on IBM Cloud.

It creates:
- a dedicated VPC with manual address prefix management
- a manual address prefix
- a subnet using that prefix with a Public Gateway attached
- VPC default security group rules to allow one or more PowerVS subnet CIDRs to reach the NLB
- a private Network Load Balancer in routing mode
- an NLB back-end pool with failsafe bypass and a listener
- a custom VPC routing table that accepts Transit Gateway ingress and advertises a `0.0.0.0/0` route via the NLB
- a Transit Gateway (global by default for multi-region PowerVS connectivity)
- one Transit Gateway connection to the VPC
- one or more Transit Gateway connections to PowerVS workspaces

## Files

- `versions.tf` - Terraform and provider version pinning
- `provider.tf` - IBM provider configuration
- `variables.tf` - all inputs
- `main.tf` - infrastructure logic
- `outputs.tf` - useful outputs
- `terraform.tfvars.example` - example values to start from

## Prerequisites

- Terraform `>= 1.5.0`
- IBM Cloud provider `~> 1.89`
- an existing IBM Cloud resource group
- one or more existing PowerVS workspaces with their CRNs
- a non-overlapping CIDR for the VPC subnet that will host the NLB
- one or more PowerVS subnet CIDRs that should be allowed to reach the NLB

## Recommended usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## Variable notes

### `powervs_workspace_crns`
Use workspace CRNs, not friendly names.

### `powervs_subnet_cidrs`
This is the list of PowerVS subnet ranges that need to traverse the NLB.

### `internet_ingress_allowed_ports`
Leave this empty if you only want outbound internet access.
If you also want inbound internet access, add only the exact ports you need.

## Notes

This repo is intended for testing in IBM Cloud Schematics and standard Terraform CLI flows. The design is sound, but the exact IBM provider schema for some Transit Gateway and Load Balancer attributes can still require one validation pass in your tenant.


## Schematics reminder

Do not keep an old `powervs_subnet_cidr` variable in your Schematics workspace. This stack uses only `powervs_subnet_cidrs` as a list of strings.
