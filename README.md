# IBM PowerVS Internet Egress Terraform

This stack creates a dedicated egress VPC with a private network load balancer in routing mode, a public gateway, a custom routing table, and one or more Transit Gateways.

## Important architecture note

This version is designed for environments where **PowerVS workspaces cannot all attach to a single global Transit Gateway**. It therefore creates **multiple Transit Gateways** and lets you map each PowerVS workspace to the correct TGW.

- Use `transit_gateways` to define the TGWs to create.
- Use `powervs_workspaces` to define which workspace attaches to which TGW.
- Set `connect_vpc = true` only on the TGW that should attach to the dedicated egress VPC.

## Key inputs

- `vpc_zone`: availability zone for the egress VPC subnet and NLB.
- `powervs_subnet_cidrs`: list of PowerVS subnets allowed to reach the NLB.
- `transit_gateways`: map of TGWs to create.
- `powervs_workspaces`: map of PowerVS workspace CRNs and the TGW each one should attach to.

## Example model

```hcl
transit_gateways = {
  eu-es = {
    name        = "internet-tgw-eu-es"
    region      = "eu-es"
    global      = false
    connect_vpc = true
  }
  eu-de = {
    name        = "internet-tgw-eu-de"
    region      = "eu-de"
    global      = false
    connect_vpc = false
  }
}

powervs_workspaces = {
  ws01 = {
    crn     = "crn:...eu-de-1..."
    tgw_key = "eu-de"
  }
  ws02 = {
    crn     = "crn:...eu-de-2..."
    tgw_key = "eu-de"
  }
  ws03 = {
    crn     = "crn:...mad02..."
    tgw_key = "eu-es"
  }
}
```

## Notes

- The NLB pool intentionally uses the failsafe policy with action `bypass`.
- `proxy_protocol` is not set because IBM network load balancer pools do not support it in this context.
- Remove stale variables such as `powervs_subnet_cidr` and `powervs_zone` from Schematics if they still appear in warnings.

## Typical workflow

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file="terraform.tfvars"
```
