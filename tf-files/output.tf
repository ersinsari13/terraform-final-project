output "load-balancer-dns" {
  value = "http://${aws_alb.app-load-balancer.dns_name}"
}
output "domain-name" {
    value = "https://phobebook.${var.domain_name}"
}