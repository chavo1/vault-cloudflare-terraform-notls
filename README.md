# This repo contain Terraform code that creates a Vault server with Consul backend without tls.
## Prerequisites

- Active domain name - You can take one from a provider of your choice
- Register or transfer the domain in Cloudflare
- AWS Account
- Install [Terraform](https://www.terraform.io/)
### How to use it
- Clone the repo
```
git clone https://github.com/chavo1/cloudflare-nginx-terraform-notls.git
cd cloudflare-nginx-terraform-notls
terraform init
terraform apply
```
