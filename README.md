# PowerVS outbound internet access hub on IBM Cloud with Terraform

This Terraform stack builds the **core egress infrastructure** for a PowerVS workspace, aligned to the steps you listed:

1. Create a dedicated VPC with **manual** address prefix management.
2. Create a manual address prefix.
3. Create a subnet using that prefix and attach a **Public Gateway**.
4. Update the VPC default security group so the **PowerVS subnet can reach the NLB**.
5. Create a **private Network Load Balancer** in **routing mode**.
6. Create an NLB **back-end pool** with **failsafe bypass** and a listener.
7. Create a **custom VPC routing table** that accepts **Transit Gateway ingress** and advertises a `0.0.0.0/0` route via the NLB.
8. Create a **local Transit Gateway** and connect:
   - the existing **PowerVS workspace**
   - the dedicated **egress VPC**

## Important reality check

This is the part nobody likes saying out loud, so I will:

- I wrote this to be **GitHub-ready**, structured, and parameterized.
- I did **not** run it against your IBM Cloud account, so treat it as a solid first version, not gospel.
- The two areas that most often need a final adjustment with IBM Cloud Terraform are:
  - the exact `ibm_tg_connection` shape for **Power Virtual Server** connections
  - the exact shape exposed by `ibm_is_lb.private_ips` in your provider release

In other words: the design is right, but you should expect **one validation pass** with `terraform init` and `terraform plan` to catch any provider-specific naming mismatch.

## Files

- `versions.tf` – Terraform and provider version pinning
- `provider.tf` – IBM provider configuration
- `variables.tf` – all inputs
- `main.tf` – infrastructure logic
- `outputs.tf` – useful outputs
- `terraform.tfvars.example` – example values to start from

## Prerequisites

- Terraform `>= 1.5.0`
- IBM Cloud provider `~> 1.89`
- An existing IBM Cloud **resource group**
- An existing **PowerVS workspace** with its **CRN**
- A non-overlapping CIDR for the VPC subnet that will host the NLB
- The **PowerVS subnet CIDR** that should be allowed to reach the NLB

## IAM / service access you will need

At minimum, the account or API key running this should have access to:

- VPC Infrastructure
- Transit Gateway
- Power Systems Virtual Server
- Resource Group read access

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

### `powervs_workspace_crn`
Use the **workspace CRN**, not a friendly name. That removes ambiguity and is safer for automation.

### `powervs_subnet_cidr`
This is the **PowerVS subnet range** that needs to traverse the NLB.

### `internet_ingress_allowed_ports`
Leave this empty if you only want **outbound internet access**.
If you also want **inbound internet access**, add only the exact ports you need. No heroics. No broad exposure unless you like pain.

## Security notes

- The stack can optionally add **SSH** and **ICMP** to the VPC default security group for troubleshooting.
- The NLB security group rule that matters most is the one allowing the **PowerVS subnet CIDR**.
- Internet-initiated inbound access is **off by default** unless you specify ports.

## Design notes

- The VPC is intentionally **dedicated** to internet ingress/egress for PowerVS.
- The NLB is **private** and uses **routing mode**, which is the right model for transparent forwarding.
- The custom routing table is configured for **Transit Gateway ingress** and **route advertisement** back to TGW.
- The first NLB private IP is used as the route **next hop**, matching the deployment guide logic.

## Known follow-up items you may want next

Once this base is in place, the next logical Terraform additions are:

- explicit route tables / network settings on the PowerVS side
- prefix filters on Transit Gateway
- optional inbound service publishing patterns
- validation guardrails for CIDR overlap
- separate security groups instead of leaning on the default VPC one

## Why this approach is sound

IBM documents that Transit Gateway connects VPCs in the same region when using **local routing**, and Power Virtual Server can be attached to Transit Gateway with the same overlap caveats as other connections. IBM also documents that PowerVS local TGW connectivity requires the workspace to be in the same region, and that overlapping prefixes must be avoided. citeturn860578view5turn860578view6

The IBM Cloud Terraform provider currently publishes provider version **1.89.0**, supports `ibm_pi_workspace` as a PowerVS data source, supports `route_mode` on `ibm_is_lb` for private load balancers, exposes `private_ips` on the load balancer resource, supports `bypass` as a failsafe pool action, and supports `advertise` on VPC routing table routes. citeturn950640search20turn784559search2turn326641search8turn277949search1turn349198search0turn959447search16
