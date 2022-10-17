resource "aws_subnet" "my_ec2_subnet_1" {
    vpc_id = var.vpc_id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
      Name : "${var.env_prefix}_subnet_1"
    }
  
}

resource "aws_internet_gateway" "my_app_igw" {
  vpc_id = var.vpc_id
      tags = {
      Name : "${var.env_prefix}_internet_getway"
    }
}


resource "aws_route_table" "my_route_table" {
    vpc_id = var.vpc_id
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


