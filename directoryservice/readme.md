# Directory Services

We use a small MS AD, since it's cheaper and we don't have a heavy loading on the domain.

## Notes

Deploying IAM changes requires that anything using STS tokens must have MFA mode turned on - if you don't, you'll get access denied errors when trying to create new IAM objects. If you are using aws-vault to manage your credentials securely, you'll need to make sure you have MFA set up, and link it to a profile name that then let's aws-vault know that you want to create a token marked with MFA on - you do this by editing your AWS CLI tools config file - like this:

`
[profile aws-cinegy-lewadmin]
region = eu-west-1

[profile terragrunt]
region = eu-west-1
source_profile = aws-cinegy-lewadmin

[profile terragrunt-admin]
region = eu-west-1
source_profile = aws-cinegy-lewadmin
mfa_serial = arn:aws:iam::12345678:mfa/lewadmin
`

Basically, if you can't get this to work without errors:
aws-vault exec terragrunt-admin -- aws iam list-roles

Then terraform is not going to work either!

For more details, see here: <https://99designs.co.uk/tech-blog/blog/2015/10/26/aws-vault/>
