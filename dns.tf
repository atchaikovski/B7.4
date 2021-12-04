resource "aws_route53_record" "master" {
  zone_id = data.aws_route53_zone.link.zone_id
  name    = var.master_host_name
  type    = "A"
  ttl     = "300"
  records = [aws_eip.master_static_ip.public_ip]
}

resource "aws_route53_record" "worker" {
  zone_id = data.aws_route53_zone.link.zone_id
  name    = var.worker_host_name
  type    = "A"
  ttl     = "300"
  records = [aws_eip.worker_static_ip.public_ip]
}