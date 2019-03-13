## Security groups

resource "aws_security_group" "lb_sg" {
  name   = "tyk_dashboard_lb"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = "${var.port}"
    to_port     = "${var.port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr}"]
  }

  ingress {
    from_port   = "${var.https_port}"
    to_port     = "${var.https_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr}"]
  }

  # ingress {
  #   from_port   = "${var.notifications_port}"
  #   to_port     = "${var.notifications_port}"
  #   protocol    = "tcp"
  #   cidr_blocks = ["${var.ingress_cidr}"]
  # }

  # "allow all" egress rule is fine for LB as listeners do the routing
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name   = "tyk_dashboard_instance"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = ["${aws_security_group.lb_sg.id}"]
  }

  # ingress {
  #   from_port       = "${var.notifications_port}"
  #   to_port         = "${var.notifications_port}"
  #   protocol        = "tcp"
  #   security_groups = ["${aws_security_group.lb_sg.id}"]
  # }

  # "allow all" egress rule is fine for instances too as they need outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Load balancer

resource "aws_lb_target_group" "web_group" {
  name     = "tyk-dashboard-web"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    path                = "/"
    interval            = 5
    timeout             = 2
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# resource "aws_lb_target_group" "notification_group" {
#   name     = "tyk-dashboard-notification"
#   port     = "${var.notifications_port}"
#   protocol = "HTTP"
#   vpc_id   = "${var.vpc_id}"

#   health_check {
#     path                = "/"
#     port                = 3000
#     protocol            = "HTTP"
#     interval            = 10
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 2
#     matcher             = "200"
#   }
# }

resource "aws_lb" "lb" {
  name               = "tyk-dashboard"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${var.lb_subnets}"]

  enable_deletion_protection       = false
  idle_timeout                     = 60
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "${var.port}"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.web_group.arn}"
  }
}

resource "aws_lb_listener" "web_https_listener" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "${var.https_port}"
  protocol          = "HTTPS"
  ssl_policy        = "${var.tls_policy}"
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.web_group.arn}"
  }

  count = "${var.enable_https ? 1 : 0}"
}

# resource "aws_lb_listener" "notification_listener" {
#   load_balancer_arn = "${aws_lb.lb.arn}"
#   port              = "${var.notifications_port}"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = "${aws_lb_target_group.notification_group.arn}"
#   }
# }

## Autoscaling and launch config

data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-*-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud_config.yml")}"

  vars {
    repository           = "${var.package_repository}"
    dashboard_version    = "${var.dashboard_version}"
    custom_config        = "${base64encode("${var.dashboard_config}")}"
    mongo_url            = "${var.mongo_url}"
    mongo_use_ssl        = "${var.mongo_use_ssl}"
    redis_host           = "${var.redis_host}"
    redis_port           = "${var.redis_port}"
    redis_password       = "${var.redis_password}"
    redis_enable_cluster = "${var.redis_enable_cluster}"
    redis_hosts          = "${var.redis_hosts}"
    gateway_host         = "${var.gateway_host}"
    gateway_port         = "${var.gateway_port}"
    gateway_secret       = "${var.gateway_secret}"
    shared_node_secret   = "${var.shared_node_secret}"
    admin_secret         = "${var.admin_secret}"
    license_key          = "${var.license_key}"
    hostname             = "${var.hostname}"
    api_hostname         = "${var.api_hostname}"
    portal_root          = "${var.portal_root}"
    enable_https         = "${var.enable_https}"

    # notifications_port   = "${var.notifications_port}"
    statsd_conn_str = "${var.statsd_conn_str}"
    statsd_prefix   = "${var.statsd_prefix}"
  }
}

data "template_cloudinit_config" "merged_cloud_config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "main.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_config.rendered}"
  }

  part {
    filename     = "metrics.cfg"
    content_type = "text/cloud-config"
    content      = "${var.metrics_cloudconfig}"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "tyk_dashboard"

  # Launch configuration
  lc_name              = "tyk_dashboard"
  image_id             = "${data.aws_ami.amazonlinux.id}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.instance_sg.id}", "${var.ssh_sg_id}"]
  key_name             = "${var.key_name}"
  user_data            = "${data.template_cloudinit_config.merged_cloud_config.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.default.name}"

  root_block_device = [
    {
      volume_size = "10"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                     = "tyk_dashboard"
  vpc_zone_identifier          = ["${var.instance_subnets}"]
  health_check_type            = "ELB"
  min_size                     = "${var.min_size}"
  max_size                     = "${var.max_size}"
  desired_capacity             = "${var.min_size}"
  wait_for_capacity_timeout    = "5m"
  recreate_asg_when_lc_changes = true                                     # Enables Blue/Green deployments, TODO: possibly marry CloudFormation for rolling upgrades
  min_elb_capacity             = "${var.min_size}"
  target_group_arns            = ["${aws_lb_target_group.web_group.arn}"]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "tyk_dashboard_scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${module.asg.this_autoscaling_group_name}"

  count = "${var.create_scaling_policies}"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "tyk_dashboard_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${module.asg.this_autoscaling_group_name}"

  count = "${var.create_scaling_policies}"
}

resource "aws_cloudwatch_metric_alarm" "scaling_alarm" {
  alarm_name          = "tyk_dashboard_scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0.5"

  dimensions {
    LoadBalancer = "${aws_lb.lb.arn}"
  }

  alarm_description = "Monitors target response time of the Tyk dashboard load balancer for scaling policy"
  alarm_actions     = ["${aws_autoscaling_policy.scale_up.arn}"]
  ok_actions        = ["${aws_autoscaling_policy.scale_down.arn}"]

  count = "${var.create_scaling_policies}"
}
