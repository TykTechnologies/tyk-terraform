locals {
  gateway_region_host   = "gw.${var.aws_region}.${var.base_domain}"
  dashboard_region_host = "admin.${var.aws_region}.${var.base_domain}"
  mdcb_region_host      = "mdcb.${var.aws_region}.${var.base_domain}"
}

provider "aws" {
  version    = "~> 1.60"
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

module "tyk_cloudwatch_dashboard" {
  source = "../../modules/tyk-metrics/cloudwatch"

  program_name     = "tyk-analytics"
  log_group_prefix = "tyk-pro-${var.aws_region}"
}

module "tyk_dashboard" {
  source = "../../modules/tyk-dashboard/aws"

  vpc_id           = "${var.vpc_id}"
  instance_subnets = "${var.instance_subnets}"
  lb_subnets       = "${var.lb_subnets}"
  ssh_sg_id        = "${var.ssh_sg_id}"
  key_name         = "${var.key_name}"
  redis_host       = "${var.redis_host}"
  redis_port       = "${var.redis_port}"
  redis_password   = "${var.redis_password}"
  mongo_url        = "${var.mongo_url}"
  mongo_use_ssl    = "${var.mongo_use_ssl}"
  license_key      = "${var.tyk_license_key}"
  instance_type    = "${var.instance_types["dashboard"]}"

  min_size                = 2
  max_size                = 4
  create_scaling_policies = true
  port                    = "80"

  # notifications_port      = "5000"
  dashboard_version  = "1.7.5"
  gateway_host       = "http://${local.gateway_region_host}"
  gateway_port       = "80"
  gateway_secret     = "${random_string.gateway_secret.result}"
  shared_node_secret = "${random_string.shared_secret.result}"
  admin_secret       = "${random_string.admin_secret.result}"
  hostname           = "admin.${var.base_domain}"
  api_hostname       = "gw.${var.base_domain}"
  portal_root        = "/portal"

  enable_ssm               = true
  enable_cloudwatch_policy = true
  enable_https             = true
  certificate_arn          = "${var.tls_certificate_arn}"
  metrics_cloudconfig      = "${module.tyk_cloudwatch_dashboard.cloud_config}"
  statsd_conn_str          = "localhost:8125"
  statsd_prefix            = "${var.aws_region}.tykDashboard"
}

resource "aws_route53_record" "dashboard_region" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.dashboard_region_host}"
  type    = "A"

  alias {
    name                   = "${module.tyk_dashboard.dns_name}"
    zone_id                = "${module.tyk_dashboard.zone_id}"
    evaluate_target_health = true
  }
}

module "tyk_cloudwatch_gateway" {
  source = "../../modules/tyk-metrics/cloudwatch"

  program_name     = "tyk"
  log_group_prefix = "tyk-pro-${var.aws_region}"
}

module "tyk_gateway" {
  source = "../../modules/tyk-gateway/aws"

  vpc_id           = "${var.vpc_id}"
  instance_subnets = "${var.instance_subnets}"
  lb_subnets       = "${var.lb_subnets}"
  ssh_sg_id        = "${var.ssh_sg_id}"
  key_name         = "${var.key_name}"
  redis_host       = "${var.redis_host}"
  redis_port       = "${var.redis_port}"
  redis_password   = "${var.redis_password}"
  instance_type    = "${var.instance_types["gateway"]}"

  min_size                  = 2
  max_size                  = 4
  create_scaling_policies   = true
  port                      = "80"
  gateway_version           = "2.7.6"
  gateway_secret            = "${random_string.gateway_secret.result}"
  shared_node_secret        = "${random_string.shared_secret.result}"
  dashboard_url             = "http://${module.tyk_dashboard.dns_name}:80"
  enable_detailed_analytics = "false"

  enable_ssm               = true
  enable_cloudwatch_policy = true
  enable_https             = true
  certificate_arn          = "${var.tls_certificate_arn}"
  metrics_cloudconfig      = "${module.tyk_cloudwatch_gateway.cloud_config}"
  statsd_conn_str          = "localhost:8125"
  statsd_prefix            = "${var.aws_region}.tykGateway"
}

resource "aws_route53_record" "gateway_region" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.gateway_region_host}"
  type    = "A"

  alias {
    name                   = "${module.tyk_gateway.dns_name}"
    zone_id                = "${module.tyk_gateway.zone_id}"
    evaluate_target_health = true
  }
}

module "tyk_cloudwatch_pump" {
  source = "../../modules/tyk-metrics/cloudwatch"

  program_name     = "tyk-pump"
  log_group_prefix = "tyk-pro-${var.aws_region}"
}

module "tyk_pump" {
  source = "../../modules/tyk-pump/aws"

  vpc_id           = "${var.vpc_id}"
  instance_subnets = "${var.instance_subnets}"
  ssh_sg_id        = "${var.ssh_sg_id}"
  key_name         = "${var.key_name}"
  redis_host       = "${var.redis_host}"
  redis_port       = "${var.redis_port}"
  redis_password   = "${var.redis_password}"
  mongo_url        = "${var.mongo_url}"
  mongo_use_ssl    = "${var.mongo_use_ssl}"
  instance_type    = "${var.instance_types["pump"]}"

  min_size                = 2
  max_size                = 4
  create_scaling_policies = true
  pump_version            = "0.5.4"

  enable_ssm               = true
  enable_cloudwatch_policy = true
  metrics_cloudconfig      = "${module.tyk_cloudwatch_pump.cloud_config}"
  statsd_conn_str          = "localhost:8125"
  statsd_prefix            = "${var.aws_region}.tykPump"
}

module "tyk_cloudwatch_mdcb" {
  source = "../../modules/tyk-metrics/cloudwatch"

  program_name     = "tyk-sink"
  log_group_prefix = "tyk-pro-${var.aws_region}"
}

module "tyk_mdcb" {
  source = "../../modules/tyk-mdcb/aws"

  vpc_id           = "${var.vpc_id}"
  instance_subnets = "${var.instance_subnets}"
  lb_subnets       = "${var.lb_subnets}"
  ssh_sg_id        = "${var.ssh_sg_id}"
  key_name         = "${var.key_name}"
  redis_host       = "${var.redis_host}"
  redis_port       = "${var.redis_port}"
  redis_password   = "${var.redis_password}"
  mongo_url        = "${var.mongo_url}"
  mongo_use_ssl    = "${var.mongo_use_ssl}"
  mdcb_token       = "${var.mdcb_token}"
  license_key      = "${var.mdcb_license_key}"
  instance_type    = "${var.instance_types["mdcb"]}"

  min_size                = 2
  max_size                = 4
  create_scaling_policies = true
  port                    = "9090"
  mdcb_version            = "1.5.7"
  forward_to_pump         = "true"

  enable_ssm               = true
  enable_cloudwatch_policy = true
  enable_tls               = true
  certificate_arn          = "${var.tls_certificate_arn}"
  metrics_cloudconfig      = "${module.tyk_cloudwatch_mdcb.cloud_config}"
  statsd_conn_str          = "localhost:8125"
  statsd_prefix            = "${var.aws_region}.tykMDCB"
}

resource "aws_route53_record" "mdcb_region" {
  zone_id = "${var.route53_zone_id}"
  name    = "${local.mdcb_region_host}"
  type    = "A"

  alias {
    name                   = "${module.tyk_mdcb.dns_name}"
    zone_id                = "${module.tyk_mdcb.zone_id}"
    evaluate_target_health = true
  }
}

output "dashboard_region_endpoint" {
  value = "${aws_route53_record.dashboard_region.name}"
}

output "gateway_region_endpoint" {
  value = "${aws_route53_record.gateway_region.name}"
}

output "mdcb_region_endpoint" {
  value = "${aws_route53_record.mdcb_region.name}"
}

output "gateway_secret" {
  value = "${random_string.gateway_secret.result}"
}

output "shared_secret" {
  value = "${random_string.shared_secret.result}"
}

output "admin_secret" {
  value = "${random_string.admin_secret.result}"
}
