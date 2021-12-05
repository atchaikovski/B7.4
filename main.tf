# ---------------------- allowed ports --------------------------------------
locals {
  master_start = [22, 2379, 6443, 10250, 10257, 10259] # from_ports
  master_end   = [22, 2380, 6443, 10250, 10257, 10259] # to_ports
}

locals {
  worker_start = [22, 10250, 30000] # from_ports
  worker_end   = [22, 10250, 32767] # to_ports
} 

# ----------- Security group resources ---------------------------------------

resource "aws_security_group" "master" {
  name = "k8s master Security Group"

  vpc_id = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = local.master_start
    content {
      from_port   = ingress.value
      to_port     = element(local.master_end, index(local.master_start,ingress.value))
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "master SecurityGroup" })

}

resource "aws_security_group" "worker" {
  name = "k8s worker Security Group"

  vpc_id = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = local.worker_start
    content {
      from_port   = ingress.value
      to_port     = element(local.worker_end, index(local.worker_start,ingress.value))
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "worker SecurityGroup" })
}

# ------------------- EC2 resources ---------------------------------

resource "aws_instance" "master" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.master.id]
#  monitoring                  = var.enable_detailed_monitoring
  key_name                    = "aws_adhoc"
  count                       = 1
  labels                      = {
    ansible-group = "master" 
  }
  associate_public_ip_address = true
  
  # provision by ansible as master using public IP
  provisioner "local-exec" {
      command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${element(aws_instance.master.*.public_ip, 0)},' --private-key ${var.private_key} -e 'pub_key=${var.public_key}' site.yaml"
  }

  tags { 
    Name = "master Server"
    ansibleFilter = "K8S01"
    ansibleNodeType = "master"
    ansibleNodeName = "master${count.index}"
  }

}

resource "aws_instance" "worker" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.worker.id]
#  monitoring                  = var.enable_detailed_monitoring
  key_name                    = "aws_adhoc"
  count                       = 1
  labels                      = {
    ansible-group = "worker" 
  }
  associate_public_ip_address = true

  # provision by ansible as worker using public IP
  provisioner "local-exec" {
      command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${element(aws_instance.worker.*.public_ip, 0)},' --private-key ${var.private_key} -e 'pub_key=${var.public_key}' site.yaml"
  }
 
 tags {
    Name = "worker Server"
    ansibleFilter = "K8S01"
    ansibleNodeType = "worker"
    ansibleNodeName = "worker${count.index}"
 }
}

# --------------- get ansible inventory file ---------------
resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
     ansible_group_shards = google_compute_instance.shard.*.labels.ansible-group,
     ansible_group_index = google_compute_instance.shard.*.labels.ansible-index,
     hostname_shards = google_compute_instance.shard.*.name,
     ansible_group_cfg = google_compute_instance.cfg.*.labels.ansible-group,
     hostname_cfg = google_compute_instance.cfg.*.name,
     ansible_group_mongos = google_compute_instance.mongos.*.labels.ansible-group,
     hostname_mongos = google_compute_instance.mongos.*.name,
     number_of_shards = range(var.shard_count)
    }
  )
  filename = "inventory"
}

# --------------- get static IP addresses ------------------

resource "aws_eip" "master_static_ip" {
  instance = aws_instance.master.id
  tags = merge(var.common_tags, { Name = "master Server IP" })
}


resource "aws_eip" "worker_static_ip" {
  instance = aws_instance.worker.id
  tags = merge(var.common_tags, { Name = "worker Server IP" })
}