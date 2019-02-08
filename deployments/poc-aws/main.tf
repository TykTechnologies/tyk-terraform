locals {
  gateway_host   = "gw.${var.base_domain}"
  dashboard_host = "admin.${var.base_domain}"
  portal_host    = "portal.${var.base_domain}"
  mdcb_host      = "mdcb.${var.base_domain}"
}

locals {
  redis_host = "${aws_elasticache_replication_group.tyk_redis.primary_endpoint_address}"
  redis_port = "${aws_elasticache_replication_group.tyk_redis.port}"
  mongo_url  = "mongodb://${aws_docdb_cluster.tyk_docdb.master_username}:${random_string.docdb_password.result}@${aws_docdb_cluster.tyk_docdb.endpoint}:${aws_docdb_cluster.tyk_docdb.port}/tyk?replicaSet=rs0"
}

provider "aws" {
  version    = ">= 1.58.0"
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "random_string" "gateway_secret" {
  length  = 16
  special = true
}

resource "random_string" "shared_secret" {
  length  = 16
  special = true
}

resource "random_string" "admin_secret" {
  length  = 16
  special = true
}

module "tyk_dashboard" {
  source = "../../modules/tyk-dashboard/aws"

  vpc_id           = "${module.vpc.vpc_id}"
  instance_subnets = "${module.vpc.private_subnets}"
  lb_subnets       = "${module.vpc.public_subnets}"
  ssh_sg_id        = "${aws_security_group.ssh_sg.id}"
  key_name         = "${var.key_name}"
  redis_host       = "${local.redis_host}"
  redis_port       = "${local.redis_port}"
  mongo_url        = "${local.mongo_url}"
  mongo_use_ssl    = "false"
  license_key      = "${var.tyk_license_key}"
  instance_type    = "${var.instance_types["dashboard"]}"

  min_size                = 1
  max_size                = 3
  create_scaling_policies = true
  port                    = "80"
  notifications_port      = "5000"
  dashboard_version       = "1.7.5"
  gateway_host            = "http://${local.gateway_host}"
  gateway_port            = "80"
  gateway_secret          = "${random_string.gateway_secret.result}"
  shared_node_secret      = "${random_string.shared_secret.result}"
  admin_secret            = "${random_string.admin_secret.result}"
  hostname                = "${local.dashboard_host}"
  api_hostname            = "${local.gateway_host}"
  portal_root             = "/portal"
}

resource "aws_route53_record" "dashboard_region" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.dashboard_host}"
  type    = "A"

  alias {
    name                   = "${module.tyk_dashboard.dns_name}"
    zone_id                = "${module.tyk_dashboard.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "portal_region" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.portal_host}"
  type    = "A"

  alias {
    name                   = "${module.tyk_dashboard.dns_name}"
    zone_id                = "${module.tyk_dashboard.zone_id}"
    evaluate_target_health = true
  }
}

module "tyk_gateway" {
  source = "../../modules/tyk-gateway/aws"

  vpc_id           = "${module.vpc.vpc_id}"
  instance_subnets = "${module.vpc.private_subnets}"
  lb_subnets       = "${module.vpc.public_subnets}"
  ssh_sg_id        = "${aws_security_group.ssh_sg.id}"
  key_name         = "${var.key_name}"
  redis_host       = "${local.redis_host}"
  redis_port       = "${local.redis_port}"
  instance_type    = "${var.instance_types["gateway"]}"

  min_size                  = 1
  max_size                  = 3
  create_scaling_policies   = true
  port                      = "80"
  gateway_version           = "2.7.6"
  gateway_secret            = "${random_string.gateway_secret.result}"
  shared_node_secret        = "${random_string.shared_secret.result}"
  dashboard_url             = "http://${module.tyk_dashboard.dns_name}:80"
  enable_detailed_analytics = "false"
}

resource "aws_route53_record" "gateway_region" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.gateway_host}"
  type    = "A"

  alias {
    name                   = "${module.tyk_gateway.dns_name}"
    zone_id                = "${module.tyk_gateway.zone_id}"
    evaluate_target_health = true
  }
}

module "tyk_pump" {
  source = "../../modules/tyk-pump/aws"

  vpc_id           = "${module.vpc.vpc_id}"
  instance_subnets = "${module.vpc.private_subnets}"
  ssh_sg_id        = "${aws_security_group.ssh_sg.id}"
  key_name         = "${var.key_name}"
  redis_host       = "${local.redis_host}"
  redis_port       = "${local.redis_port}"
  mongo_url        = "${local.mongo_url}"
  mongo_use_ssl    = "false"
  instance_type    = "${var.instance_types["pump"]}"

  min_size                = 1
  max_size                = 2
  create_scaling_policies = true
  pump_version            = "0.5.4"
}

# Uncomment to create MDCB (Terraform lacks module counts/conditionals atm)
# module "tyk_mdcb" {
#   source = "../../modules/tyk-mdcb/aws"

#   vpc_id           = "${module.vpc.vpc_id}"
#   instance_subnets = "${module.vpc.private_subnets}"
#   lb_subnets       = "${module.vpc.public_subnets}"
#   ssh_sg_id        = "${aws_security_group.ssh_sg.id}"
#   key_name         = "${var.key_name}"
#   redis_host       = "${local.redis_host}"
#   redis_port       = "${local.redis_port}"
#   mongo_url        = "${local.mongo_url}"
#   mongo_use_ssl    = "false"
#   mdcb_token       = "${var.mdcb_token}"
#   license_key      = "${var.mdcb_license_key}"
#   instance_type    = "${var.instance_types["mdcb"]}"

#   min_size                = 1
#   max_size                = 3
#   create_scaling_policies = true
#   port                    = "9090"
#   mdcb_version            = "1.5.7"
#   forward_to_pump         = "true"
# }

# resource "aws_route53_record" "mdcb_region" {
#   zone_id = "${var.route53_zone_id}"
#   name    = "${local.mdcb_host}"
#   type    = "A"

#   alias {
#     name                   = "${module.tyk_mdcb.dns_name}"
#     zone_id                = "${module.tyk_mdcb.zone_id}"
#     evaluate_target_health = true
#   }
# }

output "dashboard_region_endpoint" {
  value = "${aws_route53_record.dashboard_region.name}"
}

output "portal_region_endpoint" {
  value = "${aws_route53_record.portal_region.name}"
}

output "gateway_region_endpoint" {
  value = "${aws_route53_record.gateway_region.name}"
}

# output "mdcb_region_endpoint" {
#   value = "${aws_route53_record.mdcb_region.name}"
# }

output "gateway_secret" {
  value = "${random_string.gateway_secret.result}"
}

output "shared_secret" {
  value = "${random_string.shared_secret.result}"
}

output "admin_secret" {
  value = "${random_string.admin_secret.result}"
}

output "docdb_password" {
  value = "${random_string.docdb_password.result}"
}
