output "load-balancer-dns" {
  value = "http://${aws_lb.ELB.dns_name}" 
}
output address {
  value = aws_db_instance.db_project.address
}