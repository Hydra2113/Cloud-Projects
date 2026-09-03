# Contains primary resource definitions and resource blocks

locals {
  nacl_rules = {
    ssh_inbound    = { rule_number = 100, egress = false, from_port = 22, to_port = 22 }
    ephemeral_out  = { rule_number = 200, egress = true, from_port = 1024, to_port = 65535 }
    http_out       = { rule_number = 300, egress = true, from_port = 80, to_port = 80 }
    https_out      = { rule_number = 310, egress = true, from_port = 443, to_port = 443 }
    inbound_return = { rule_number = 400, egress = false, from_port = 1024, to_port = 65535 }
  }
}


resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpc1_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "vpc1"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet1"
  }
}

resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "igw1"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }

  tags = {
    Name = "rt1"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_network_acl" "nacl1" {
  vpc_id     = aws_vpc.vpc1.id
  subnet_ids = [aws_subnet.subnet1.id]

  tags = {
    Name = "nacl1"
  }
}

resource "aws_network_acl_rule" "nacl1" {
  for_each       = local.nacl_rules
  network_acl_id = aws_network_acl.nacl1.id
  rule_number    = each.value.rule_number
  egress         = each.value.egress
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}


resource "aws_vpc" "vpc2" {
  cidr_block           = var.vpc2_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "vpc2"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = var.subnet2_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet2"
  }
}

resource "aws_internet_gateway" "igw2" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "igw2"
  }
}

resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw2.id
  }

  tags = {
    Name = "rt2"
  }
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt2.id
}

resource "aws_network_acl" "nacl2" {
  vpc_id     = aws_vpc.vpc2.id
  subnet_ids = [aws_subnet.subnet2.id]

  tags = {
    Name = "nacl2"
  }
}

resource "aws_network_acl_rule" "nacl2" {
  for_each       = local.nacl_rules
  network_acl_id = aws_network_acl.nacl2.id
  rule_number    = each.value.rule_number
  egress         = each.value.egress
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}
