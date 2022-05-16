data "aws_availability_zones" "available" {}

resource "aws_vpc" "terVPC" {
  cidr_block = var.vpc_cidr
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
  name   = "allow ssh and http(s)"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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
