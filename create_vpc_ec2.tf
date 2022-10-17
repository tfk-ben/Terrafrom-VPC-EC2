provider "aws"{
    region = "eu-west-3"
}

 resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}_vpc" 
     } 
}

module "subnet" {
  source = "./modules/subnet"
    subnet_cidr_block = var.subnet_cidr_block
    avail_zone = var.avail_zone
    env_prefix = var.env_prefix
    vpc_id = aws_vpc.my_vpc.id

}

module "webserver" {
    source = "./modules/webserver"

    vpc_id = aws_vpc.my_vpc.id
    env_prefix = var.env_prefix

    public_key_location = var.public_key_location
    instance_type = var.instance_type
    subnet_id = module.subnet.subnet.id
    avail_zone = var.avail_zone
}

output "my_ip" {
  value = module.webserver.ec2_public_ip
  
}


