module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name           = "${var.project_name}-vpc"
  cidr           = var.vpc_cidr
  azs            = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets = [for subnet in range(var.az_count) : cidrsubnet(var.vpc_cidr, 2, subnet)]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Owner                                       = var.owner_tag
    "kubernetes.io/cluster/${var.project_name}" = "managed"
  }
}

resource "aws_security_group" "all_nodes" {
  name_prefix = "${var.project_name}-"
  description = "Access to all nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.admin_cidrs
  }

  ingress {
    description = "All from this group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                        = "${var.project_name}-nodes"
    Owner                                       = var.owner_tag
    "kubernetes.io/cluster/${var.project_name}" = "managed"
  }
}


