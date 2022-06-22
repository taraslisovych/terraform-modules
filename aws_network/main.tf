data "aws_availability_zones" "available" {}

resource "aws_vpc" "terVPC" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    "Name" = "VPC for <${var.env}> env"
  }
}

resource "aws_internet_gateway" "terGW" {
  vpc_id = aws_vpc.terVPC.id

  tags = {
    "Name" = "Internet Gateway for <${var.env}> env"
  }
}

#----------------Private Subnets +++++++++++++++++++++

resource "aws_subnet" "terPrivateSubnets" {
  count             = var.private_network_count
  vpc_id            = aws_vpc.terVPC.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    "Name" = "Private Subnet ${count.index + 1} in <${var.env}> env"
  }
}

#----------------Public Subnets +++++++++++++++++++++

resource "aws_subnet" "terPublicSubnets" {
  count                   = var.public_network_count
  vpc_id                  = aws_vpc.terVPC.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + var.private_network_count)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "Public Subnet ${count.index + 1} in <${var.env}> env"
  }
}

resource "aws_route_table" "terRT" {
  vpc_id = aws_vpc.terVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terGW.id
  }

  tags = {
    "Name" = "Main RT in <${var.env}> env"
  }
}

/*
resource "aws_placement_group" "terPlacementGroup" {
  name     = "EC2 placement group - ${var.placement_group}"
  strategy = var.placement_group
}
*/

resource "aws_route_table_association" "terRTtoPublicSubnet" {
  count          = var.public_network_count
  route_table_id = aws_route_table.terRT.id
  subnet_id      = aws_subnet.terPublicSubnets[count.index].id
}

resource "aws_security_group" "terDefaultSG" {
  vpc_id = aws_vpc.terVPC.id
  name   = "allow all traffic"

  ingress {
    description = "Allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "Default SG in <${var.env}> env"
  }
}

#-----------Key Pair -------------------------------
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "${var.env} key" # Create a "myKey" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./myKey.pem"
  }
}
