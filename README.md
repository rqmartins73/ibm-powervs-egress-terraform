# PowerVS regional egress hubs for IBM Cloud

This stack creates one independent egress hub per region. Each regional hub creates:
- one VPC
- one manual address prefix
- one subnet with Public Gateway
- one private NLB in route mode
- one routing table with default route to the NLB
- one local Transit Gateway
- one VPC connection to the local TGW
- one TGW connection per PowerVS workspace mapped to that region

## Important
This version uses explicit provider aliases for supported VPC regions:
- `eu-de`
- `eu-es`

That is required because VPC resources are region-scoped in the provider, and a single provider instance cannot safely create VPC resources in multiple regions.

## Important limitation
Transit Gateway local routing requires the connected network to be local to the gateway region. Therefore:
- a `eu-de` VPC must connect to a `eu-de` local TGW
- a `eu-es` VPC must connect to a `eu-es` local TGW

## Madrid note
The Madrid VPC region is `eu-es`, but the PowerVS data centers are `mad02` and `mad04`. Use a valid Madrid VPC zone such as `eu-es-1`, `eu-es-2`, or `eu-es-3` for VPC resources, and map the Madrid PowerVS workspace CRNs to the `eu-es` regional hub.
