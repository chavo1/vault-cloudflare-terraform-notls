# Configure the Cloudflare provider
provider "cloudflare" {
  email   = var.email
  api_key = var.api_key
}
# Create a record
resource "cloudflare_record" "vault" {
  zone_id = var.zone_id
  name    = var.vault_name
  value   = aws_instance.vault.public_ip
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "consul" {
  zone_id = var.zone_id
  name    = var.consul_name
  value   = aws_instance.consul.public_ip
  type    = "A"
  proxied = false
}