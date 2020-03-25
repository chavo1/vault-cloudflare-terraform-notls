output "public_ip_vault" {
  value = aws_instance.vault.*.public_ip
}
output "public_dns_vault" {
  value = aws_instance.vault.*.public_dns
}
output "hostname_vault" {
  value = cloudflare_record.vault.*.hostname
}
output "public_ip_consul" {
  value = aws_instance.consul.*.public_ip
}
output "public_dns_consul" {
  value = aws_instance.consul.*.public_dns
}
output "hostname_consul" {
  value = cloudflare_record.consul.*.hostname
}
