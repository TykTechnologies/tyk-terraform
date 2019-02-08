resource "aws_security_group" "elasticache_sg" {
  name        = "tyk_elasticache_sg"
  description = "Allow Redis inbound traffic from anywhere in VPC"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["${module.vpc.vpc_cidr_block}"]
  }
}

resource "aws_elasticache_replication_group" "tyk_redis" {
  replication_group_id          = "tyk-redis-cluster"
  replication_group_description = "Tyk Redis cluster"
  node_type                     = "cache.t2.small"
  port                          = 6379
  engine                        = "redis"
  engine_version                = "5.0.0"
  number_cache_clusters         = "${length(var.aws_azs)}"

  # parameter_group_name          = "default.redis5.0.cluster.on"
  parameter_group_name       = "default.redis5.0"
  automatic_failover_enabled = true
  availability_zones         = ["${var.aws_azs}"]
  subnet_group_name          = "${module.vpc.elasticache_subnet_group_name}"
  security_group_ids         = ["${aws_security_group.elasticache_sg.id}"]

  # cluster_mode {
  #   replicas_per_node_group = 1
  #   num_node_groups         = 2
  # }
}

# WARNING: DocumentDB part is incomplete due to unfinished support in the Terraform AWS provider, to be updated
# Note: There are also oddities and unexpected behaviour so beware as this all is pretty new for both AWS and TF

resource "aws_docdb_subnet_group" "tyk" {
  name        = "tyk-vpc"
  subnet_ids  = ["${module.vpc.database_subnets}"]
  description = "DocumentDB subnet group for Tyk"
}

resource "aws_security_group" "docdb_sg" {
  name        = "tyk_docdb_sg"
  description = "Allow DocumentDB inbound traffic from anywhere in VPC"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["${module.vpc.vpc_cidr_block}"]
  }
}

resource "aws_docdb_cluster_parameter_group" "tyk_params" {
  family      = "docdb3.6"
  name        = "tyk"
  description = "docdb cluster parameter group for Tyk"

  # DocDB flavour of TLS isn't currently supported by Tyk at this time
  parameter {
    name  = "tls"
    value = "disabled"
  }
}

resource "random_string" "docdb_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"  # DocDB doesn't allow  / (slash), " (double quote) or @ (at symbol)
}

resource "aws_docdb_cluster" "tyk_docdb" {
  cluster_identifier              = "docdb-poc"
  engine                          = "docdb"
  master_username                 = "tyk"
  master_password                 = "${random_string.docdb_password.result}"
  port                            = "27017"
  backup_retention_period         = "1"
  skip_final_snapshot             = true
  storage_encrypted               = false
  availability_zones              = ["${var.aws_azs}"]
  db_subnet_group_name            = "${aws_docdb_subnet_group.tyk.name}"
  db_cluster_parameter_group_name = "${aws_docdb_cluster_parameter_group.tyk_params.name}"
  vpc_security_group_ids          = ["${aws_security_group.docdb_sg.id}"]
}

# TODO: Add DocDB cluster instance definitions once provider is updated

