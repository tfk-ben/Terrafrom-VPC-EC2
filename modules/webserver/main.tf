data "aws_ami" "latest_image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
  filter {
       name   = "virtualization-type"
       values = ["hvm"]
 }
}

resource "aws_security_group" "myapp_sg" {
  name = "myapp-sg"
  vpc_id = var.vpc_id

  ingress = [{
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false
  },

    { 
      description = "HTTP"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false
  }]

    egress = [{ 
    description  = "for all outgoing traffics"
    from_port = 0
    to_port = 0 
    protocol = "-1"  
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
    self = false
  }]

    tags = {
      Name : "${var.env_prefix}_sg"
    }
}


 
resource "aws_key_pair" "sshkey" {
    key_name = "key"
    public_key = file(var.public_key_location)
}


resource "aws_instance" "ec2-instance" {
    ami = data.aws_ami.latest_image.id
    instance_type = var.instance_type

    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.myapp_sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true


    # key_name = "yourkey.pem" or
    key_name = aws_key_pair.sshkey.key_name


       #user_data = file("entry-script.sh")
        user_data = <<EOF
                  #!/bin/bash
                  sudo yum update -y && sudo yum install -y docker 
                  sudo systemctl start docker 
                  sudo usermod -aG Docker ec2-user 
                  docker run -p 8080:80 nginx 
                EOF


      tags = {
      Name : "${var.env_prefix}_ec2_instance"
    }
}

