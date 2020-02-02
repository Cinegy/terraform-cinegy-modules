# Cinegy Terraform Modules for Cinegy Central Deployment

## VPC Definition

This module is the root definition for the VPC that most other elements will be bound against.

Within this module, the subnets, core routing and internet access are all defined and connected.

Some other commonly re-used things are stored within the VPC - such as base security groups and IAM permissions.

Various elements are exported, such as the VPC ID, which other dependent modules can then use to interact with this VPC and create connections.

Needless to say, breaking the core VPC can wreck a lot of things... change this with extreme care!