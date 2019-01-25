# Cinegy Terraform Modules for Cinegy Applications

Terraform Modules defining Cinegy application cloud deployment, referenced by any deployments. We keep any modules for internal business deployments in another repository (or will do, once we define some). This way, we can provide customers access to these modules without exposing internal business parts.

## Terra-what?

Terraform is a tool that reads declarative files and uses them to create a desired state on the targetted infrastructure. We use Terraform to define everything we want to deploy into the cloud (currently really meaning AWS). Terraform allows us to use a simple configuration language to declare how we want various infrastructure elements deployed.

This repository is where we store the 'blueprints' for our cloud environments. If we want to define an Air Engine VM for HD with graphics, this is where we define that VM configuration.

When we want to actually use that VM, we go to a 'deployments' repository and back-reference via GIT to the 'blueprint' held in this repository and the version of that blueprint we want to deploy.

Deployments use an S3 bucket to hold the current state for any actual roll-out (which should only be modified by running terraform against the deployments repository) so that we can work as a team defining deployments and evolving / improving them as well as easily replicating them.

## Why is this good?

It's very early days, so this is rapidly evolving for Cinegy. However, main benefits are:

- much easier to maintain our cloud enviroments this way, because they are defined and under version control
- we can duplicate entire environments for testing or staging
- it's very quick to create a new environment for a new customer from the blueprints
- we can create sub-environments for internal teams or even individual developers trivially
- we can automate deployments and testing
- there is a 'destroy' option to terraform, which winds back the entire environment (which is awesome - no more trashed clouds!)

## What do we use?

We've been building against Terraform 0.11.10, which does all the heavy lifting. This references the AWS provider for terraform, but that's all managed internally by terraform. We then use our internal GitLab system to store configuration and modules (like this repo) and expect Terragrunt to help make this work in teams better.
 

The current curated list of versions you should be using to match the team working on master is:
- Terraform v0.11.10 (core tool for actually doing work)
- - https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_windows_amd64.zip
- Terragrunt v0.16.14 (wrapper to terraform, which provides provides easier team-working and templating from blueprint modules to deployments)
- - https://github.com/gruntwork-io/terragrunt/releases/tag/v0.16.14
- AWS Vault v4.4.1 (used to easily store encrypted secrets, and push AWS values into environment variables at runtime)
- - https://github.com/99designs/aws-vault/releases/tag/v4.4.1
- AWS S3 Buckets & DynamoDB (for holding in a centralized area the terraform state, and to hold locking flags for terragrunt)
- AWS Secrets Manager (for holding sensitive values that scripts need access to, secured via IAM roles)

## How would I run this?

Our current best-practice is to inject credentials to a call to terragrunt, which itself wraps around terraform to execute operations. Normally, deployment configuration will run against tag versions in git. While developing, the git tag can be over-ridden to a locally checked out and modified version with a source command.

Basically, here is a command I would use to get the directoryservices area to roll out in dev:

`
aws-vault exec terragrunt-admin -- terragrunt apply --terragrunt-source ..\..\..\terraform-cinegy-modules\directoryservice\
`