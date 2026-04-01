# PowerVS outbound internet access hubs on IBM Cloud with Terraform

This Terraform stack builds one egress hub per region.

For each entry in `regional_hubs`, it creates:
- one dedicated VPC with manual address prefix management
- one manual address prefix
- one subnet using that prefix with a Public Gateway attached
- VPC default security group rules to allow the regional PowerVS subnet CIDRs to reach the NLB
- one private Network Load Balancer in routing mode
- one NLB back-end pool with failsafe bypass and one listener
- one custom VPC routing table that accepts Transit Gateway ingress and advertises a `0.0.0.0/0` route via the regional NLB
- one local Transit Gateway
- one Transit Gateway connection from the regional VPC to the regional TGW
- one or more Transit Gateway connections from the correct PowerVS workspaces to the correct regional TGW

## Why this version exists

A global Transit Gateway cannot be used when a PowerVS workspace is already connected to another global TGW. The practical answer is to build one local TGW per target region and attach each workspace to the correct TGW.

That also means each region needs its own:
- VPC
- subnet
- Public Gateway
- NLB
- routing table
- local TGW

## Files

- `versions.tf` - Terraform and provider version pinning
- `provider.tf` - IBM provider configuration
- `variables.tf` - all inputs
- `main.tf` - infrastructure logic
- `outputs.tf` - useful outputs
- `terraform.tfvars.example` - example values to start from

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

## Input model

### `regional_hubs`
This is the main map. Each key represents one target region where Terraform will create a full hub. Example:

```hcl
regional_hubs = {
  eu-es = {
    region                  = "eu-es"
    zone                    = "eu-es-2"
    vpc_address_prefix_cidr = "172.25.2.0/24"
    powervs_subnet_cidrs    = ["172.26.11.0/24", "172.26.12.0/24"]
  }
  eu-de = {
    region                  = "eu-de"
    zone                    = "eu-de-2"
    vpc_address_prefix_cidr = "172.25.3.0/24"
    powervs_subnet_cidrs    = ["172.26.2.0/24", "172.26.4.0/24"]
  }
}
```

### `powervs_workspaces`
Each workspace must point to the correct hub key.

```hcl
powervs_workspaces = {
  ws01 = {
    crn        = "crn:..."
    region_key = "eu-de"
  }
  ws03 = {
    crn        = "crn:..."
    region_key = "eu-es"
  }
}
```

## Notes

- This stack no longer uses a single global TGW.
- This stack no longer sets `proxy_protocol` on the NLB pool because network load balancer pools do not support it.
- Remove stale Schematics variables such as `powervs_subnet_cidr` and `powervs_zone`.


## Design note

`regional_hubs` is now the source of truth for **which regions get infrastructure**.
If you want Terraform to create a VPC, NLB, subnet, routing table, and local TGW in a region, that region must exist in `regional_hubs`.
