output "master_server_ip" {
  value = aws_eip.master_static_ip.public_ip
}

output "worker_server_ip" {
  value = aws_eip.worker_static_ip.public_ip
}

output "master_sg_id" {
  value = aws_security_group.master.id
}

output "worker_sg_id" {
  value = aws_security_group.worker.id
}
