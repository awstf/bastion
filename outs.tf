output "security_group_id" {
  value = aws_security_group.sg.id
}

output "user_data" {
  value = templatefile("${path.module}/data/init.yaml", {
    ips    = aws_eip.ip.*.id,
    region = data.aws_region.current.name
  })
}
