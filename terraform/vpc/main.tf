provider "aws" {
  region = "us-east-1"
}

# Query all avilable Availibility Zone
data "aws_availability_zones" "available" {}

# VPC Creation

resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-new-test-terraform-vpc"
  }
}

# Creating Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "my-test-igw"
  }
}

# Public Route Table

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "my-test-public-route"
  }
}

# Private Route Table

resource "aws_default_route_table" "private_route" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  route {
    nat_gateway_id = "${aws_nat_gateway.my-test-nat-gateway.id}"
    cidr_block     = "0.0.0.0/0"
  }

  tags = {
    Name = "my-private-route-table"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  count                   = 2
  cidr_block              = "${var.public_cidrs[count.index]}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"

  tags = {
    Name = "my-test-public-subnet.${count.index + 1}"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  count             = 2
  cidr_block        = "${var.private_cidrs[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  tags = {
    Name = "my-test-private-subnet.${count.index + 1}"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_subnet_assoc" {
  count          = 2
  route_table_id = "${aws_route_table.public_route.id}"
  subnet_id      = "${aws_subnet.public_subnet.*.id[count.index]}"
  depends_on     = [aws_route_table.public_route, aws_subnet.public_subnet]
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_subnet_assoc" {
  count          = 2
  route_table_id = "${aws_default_route_table.private_route.id}"
  subnet_id      = "${aws_subnet.private_subnet.*.id[count.index]}"
  depends_on     = [aws_default_route_table.private_route, aws_subnet.private_subnet]
}

# Security Group Creation
resource "aws_security_group" "test_sg" {
  name   = "my-test-sg"
  vpc_id = "${aws_vpc.main.id}"
}

# Ingress Security Port 22
resource "aws_security_group_rule" "ssh_inbound_access" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.test_sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_inbound_access" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.test_sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# All OutBound Access
resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.test_sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_eip" "my-test-eip" {
  vpc = true
}

resource "aws_nat_gateway" "my-test-nat-gateway" {
  allocation_id = "${aws_eip.my-test-eip.id}"
  subnet_id     = "${aws_subnet.public_subnet.0.id}"
}

# Adding Route for Transit Gateway

resource "aws_route" "my-tgw-route" {
  route_table_id         = "${aws_route_table.public_route.id}"
  destination_cidr_block = ""   /*provide the cidr block of another VPC(target vpc)*/
  transit_gateway_id     = "${aws_ec2_transit_gateway.my-test-tgw.id}"
}
 

/*to add route to transit gateway we have to create transit gateway*/

# creating transit gateway

resource "aws_ec2_transit_gateway" "my-test-tgw" {
 description = "my-test-transit-gateway"
 amazon_side_asn = 64512
 auto_accept_shared_attachments = "disable"
 default_route_table_association = "enable"
 default_route_table_propagation = "enable"
 dns_support = "enable"
 vpn_ecmp_support = "enable"

 tags = {
  Name = "my-test-transit-gateway"
 }
}

# attaching subnets to transit gateway

resource "aws_ec2_transit_gateway_vpc_attachment" "my-test-transit-gateway-attachment" {
 transit_gateway_id = "${aws_ec2_transit_gateway.my-test-tgw.id}"
 vpc_id = "${aws_vpc.main.id}"
 dns_support = "enable"
 subnet_ids = ["${aws_subnet.public_subnet.0.id}", "${aws_subnet.public_subnet.1.id}"]
  tags = {
  Name = "my-test-tgw-vpc-attachment"
 }
}