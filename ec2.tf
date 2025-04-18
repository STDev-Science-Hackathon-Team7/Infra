resource "aws_key_pair" "deployer" {
  key_name   = "counting-stars-key"
  public_key = file(var.public_key_path)
}

resource "aws_ebs_volume" "app_data" {
  availability_zone = var.availability_zone
  size              = 500
  type              = "gp3"
  iops              = 3000
  throughput        = 125

  tags = {
    Name = "counting-stars-data"
  }
}

resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = "c6i.4xlarge"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.counting-stars.id]
  subnet_id              = data.aws_subnets.default.ids[0]
  availability_zone      = var.availability_zone

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "counting-stars-server"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3-pip python3-venv build-essential libssl-dev libffi-dev python3-dev python3-opencv nginx mongodb
              systemctl enable mongodb
              systemctl start mongodb
              
              ufw allow 22
              ufw allow 80
              ufw allow 443
              ufw allow 8000
              EOF
}

resource "aws_volume_attachment" "app_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.app_data.id
  instance_id = aws_instance.app_server.id
}

resource "aws_eip" "app_eip" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "counting-stars-eip"
  }
}