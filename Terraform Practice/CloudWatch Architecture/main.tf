# Contains primary resource definitions and resource blocks

locals {
  # every entry carries the same keys so the map has one consistent object type;
  # icmp_* are null for tcp rules and from/to_port are null for icmp rules
  nacl_rules = {
    ssh_inbound    = { rule_number = 100, egress = false, protocol = "tcp", from_port = 22, to_port = 22, icmp_type = null, icmp_code = null }
    ephemeral_out  = { rule_number = 200, egress = true, protocol = "tcp", from_port = 1024, to_port = 65535, icmp_type = null, icmp_code = null }
    http_out       = { rule_number = 300, egress = true, protocol = "tcp", from_port = 80, to_port = 80, icmp_type = null, icmp_code = null }
    https_out      = { rule_number = 310, egress = true, protocol = "tcp", from_port = 443, to_port = 443, icmp_type = null, icmp_code = null }
    inbound_return = { rule_number = 400, egress = false, protocol = "tcp", from_port = 1024, to_port = 65535, icmp_type = null, icmp_code = null }
    icmp_in        = { rule_number = 500, egress = false, protocol = "icmp", from_port = null, to_port = null, icmp_type = -1, icmp_code = -1 }
    icmp_out       = { rule_number = 510, egress = true, protocol = "icmp", from_port = null, to_port = null, icmp_type = -1, icmp_code = -1 }
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

  tags = {
    Name = "rt1"
  }
}

resource "aws_route" "igw_route1" {
  route_table_id         = aws_route_table.rt1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw1.id
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
  protocol       = each.value.protocol
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  icmp_type      = each.value.icmp_type
  icmp_code      = each.value.icmp_code
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

  tags = {
    Name = "rt2"
  }
}

resource "aws_route" "igw_route2" {
  route_table_id         = aws_route_table.rt2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw2.id
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
  protocol       = each.value.protocol
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  icmp_type      = each.value.icmp_type
  icmp_code      = each.value.icmp_code
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_vpc_peering_connection" "vpc_connector" {
  vpc_id      = aws_vpc.vpc1.id
  peer_vpc_id = aws_vpc.vpc2.id
  auto_accept = true

  tags = {
    Name = "vpc_connector"
  }
}

resource "aws_route" "peer_route1" {
  route_table_id            = aws_route_table.rt1.id
  destination_cidr_block    = aws_vpc.vpc2.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_connector.id
}

resource "aws_route" "peer_route2" {
  route_table_id            = aws_route_table.rt2.id
  destination_cidr_block    = aws_vpc.vpc1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_connector.id
}


# ---------------------------------------------------------------------------
# Phase 4 - compute
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_key_pair" "tf_practice" {
  key_name   = "tf-practice"
  public_key = file(pathexpand("~/.ssh/tf-practice.pub"))

  tags = {
    Name = "tf-practice"
  }
}

resource "aws_security_group" "sg1" {
  name        = "sg1"
  description = "ssh from my ip, icmp from vpc2"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "ssh from my ip"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "icmp from the peered vpc"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.vpc2.cidr_block]
  }

  egress {
    description = "all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg1"
  }
}

resource "aws_security_group" "sg2" {
  name        = "sg2"
  description = "ssh from my ip, icmp from vpc1"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    description = "ssh from my ip"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "icmp from the peered vpc"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.vpc1.cidr_block]
  }

  egress {
    description = "all outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg2"
  }
}

resource "aws_instance" "instance1" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.sg1.id]
  key_name               = aws_key_pair.tf_practice.key_name

  tags = {
    Name = "instance1"
  }
}

resource "aws_instance" "instance2" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.sg2.id]
  key_name               = aws_key_pair.tf_practice.key_name

  tags = {
    Name = "instance2"
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/vpc-flow-logs/${var.project_name}"
  retention_in_days = 90

  tags = {
    Name = "log_group"
  }
}

# trust policy: lets the VPC Flow Logs service assume this role.
# the SourceAccount condition stops another account's flow log from using it.
resource "aws_iam_role" "log_role" {
  name = "${var.project_name}-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })

  tags = {
    Name = "log_role"
  }
}

# permissions policy: what the role may do once assumed.
resource "aws_iam_role_policy" "log_role_policies" {
  name = "${var.project_name}-flow-logs"
  role = aws_iam_role.log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = [
          aws_cloudwatch_log_group.log_group.arn,
          "${aws_cloudwatch_log_group.log_group.arn}:*",
        ]
      },
      {
        # DescribeLogGroups does not support resource-level permissions
        Effect   = "Allow"
        Action   = "logs:DescribeLogGroups"
        Resource = "*"
      },
    ]
  })
}

resource "aws_flow_log" "flow_log1" {
  vpc_id               = aws_vpc.vpc1.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.log_group.arn
  iam_role_arn         = aws_iam_role.log_role.arn

  tags = {
    Name = "flow_log1"
  }
}

resource "aws_flow_log" "flow_log2" {
  vpc_id               = aws_vpc.vpc2.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.log_group.arn
  iam_role_arn         = aws_iam_role.log_role.arn

  tags = {
    Name = "flow_log2"
  }
}