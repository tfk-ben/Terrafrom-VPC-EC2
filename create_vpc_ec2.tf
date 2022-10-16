provider "aws"{
    region = "eu-west-3"
}



resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}_vpc" 
     } 
}

resource "aws_subnet" "my_ec2_subnet_1" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
      Name : "${var.env_prefix}_subnet_1"
    }
  
}

resource "aws_internet_gateway" "my_app_igw" {
  vpc_id = aws_vpc.my_vpc.id
      tags = {
      Name : "${var.env_prefix}_internet_getway"
    }
}


resource "aws_route_table" "my_route_table" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_app_igw.id 
    } 
    tags = {
      Name : "${var.env_prefix}_route_table"
    }
}


resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.my_ec2_subnet_1.id
  route_table_id = aws_route_table.my_route_table.id
}


resource "aws_security_group" "myapp_sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.my_vpc.id

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

output "aws_ami_id" {
    value = data.aws_ami.latest_image.id
} 

resource "aws_key_pair" "sshkey" {
    key_name = "key"
    public_key = file(var.public_key_location)
}


resource "aws_instance" "ec2-instance" {
    ami = data.aws_ami.latest_image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.my_ec2_subnet_1.id
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

output "ec2_public_ip"{
    value = aws_instance.ec2-instance.public_ip
}