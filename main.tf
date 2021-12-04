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
  monitoring                  = var.enable_detailed_monitoring
  key_name                    = "aws_adhoc"
  associate_public_ip_address = true
  
    provisioner "file" {
      source      = "${path.module}/pack.tar.gz"
      destination = "pack.tar.gz"
      
      connection {
         type        = "ssh"
         user        = "ec2-user"
         host        = "${element(aws_instance.master.*.public_ip, 0)}"
         private_key = "${file("~/.ssh/aws_adhoc.pem")}"      
      } 
    } 

    provisioner "remote-exec" {
      connection {
         type        = "ssh"
         user        = "ec2-user"
         host        = "${element(aws_instance.master.*.public_ip, 0)}"
         private_key = "${file("~/.ssh/aws_adhoc.pem")}"      
      } 

    inline = [
      "tar zxvf pack.tar.gz",
      "chmod +x install_kubeadm.sh",
      "./install_kubeadm.sh"
    ]
  }

  tags = merge(var.common_tags, { Name = "master Server" })

}

resource "aws_instance" "worker" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.worker.id]
  monitoring                  = var.enable_detailed_monitoring
  key_name                    = "aws_adhoc"
  associate_public_ip_address = true
  
    provisioner "file" {
      source      = "${path.module}/pack.tar.gz"
      destination = "pack.tar.gz"
      
      connection {
         type        = "ssh"
         user        = "ec2-user"
         host        = "${element(aws_instance.master.*.public_ip, 0)}"
         private_key = "${file("~/.ssh/aws_adhoc.pem")}"      
      } 
    } 

   provisioner "remote-exec" {
      connection {
         type        = "ssh"
         user        = "ec2-user"
         host        = "${element(aws_instance.master.*.public_ip, 0)}"
         private_key = "${file("~/.ssh/aws_adhoc.pem")}"      
      } 

    inline = [
      "tar zxvf pack.tar.gz",
      "chmod +x install_kubeadm.sh",
      "./install_kubeadm.sh"
    ]
  }

  tags = merge(var.common_tags, { Name = "worker Server" })

}


resource "aws_eip" "master_static_ip" {
  instance = aws_instance.master.id
  tags = merge(var.common_tags, { Name = "master Server IP" })
}


resource "aws_eip" "worker_static_ip" {
  instance = aws_instance.worker.id
  tags = merge(var.common_tags, { Name = "worker Server IP" })
}