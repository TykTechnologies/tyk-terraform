module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tyk-vpc"
  cidr = "${var.vpc_cidr}"

  azs                 = ["${var.aws_azs}"]
  private_subnets     = ["${var.private_subnets}"]
  public_subnets      = ["${var.public_subnets}"]
  elasticache_subnets = ["${var.elasticache_subnets}"]
  database_subnets    = ["${var.docdb_subnets}"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_security_group" "ssh_sg" {
  name        = "tyk_ssh_sg"
  description = "Allow SSH inbound traffic from anywhere"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
