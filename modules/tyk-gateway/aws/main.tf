## Security groups

resource "aws_security_group" "lb_sg" {
  name   = "tyk_gateway_lb"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = "${var.port}"
    to_port     = "${var.port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr}"]
  }

  # "allow all" egress rule is fine for LB as listeners do the routing
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name   = "tyk_gateway_instance"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.lb_sg.id}"]
  }

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
  name     = "tyk-gateway-web"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    path                = "/hello"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb" "lb" {
  name               = "tyk-gateway"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${var.lb_subnets}"]

  enable_deletion_protection       = false
  idle_timeout                     = 320
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
    gateway_version      = "${var.gateway_version}"
    custom_config        = "${base64encode("${var.gateway_config}")}"
    redis_host           = "${var.redis_host}"
    redis_port           = "${var.redis_port}"
    redis_password       = "${var.redis_password}"
    redis_enable_cluster = "${var.redis_enable_cluster}"
    redis_hosts          = "${var.redis_hosts}"
    gateway_secret       = "${var.gateway_secret}"
    shared_node_secret   = "${var.shared_node_secret}"
    dashboard_url        = "${var.dashboard_url}"
  }
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "tyk_gateway"

  # Launch configuration
  lc_name         = "tyk_gateway"
  image_id        = "${data.aws_ami.amazonlinux.id}"
  instance_type   = "${var.instance_type}"
  security_groups = ["${aws_security_group.instance_sg.id}", "${var.ssh_sg_id}"]
  key_name        = "${var.key_name}"
  user_data       = "${data.template_file.cloud_config.rendered}"

  root_block_device = [
    {
      volume_size = "10"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                     = "tyk_gateway"
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
  name                   = "tyk_gateway_scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${module.asg.this_autoscaling_group_name}"

  count = "${var.create_scaling_policies}"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "tyk_gateway_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${module.asg.this_autoscaling_group_name}"

  count = "${var.create_scaling_policies}"
}

resource "aws_cloudwatch_metric_alarm" "scaling_alarm" {
  alarm_name          = "tyk_gateway_scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions {
    AutoScalingGroupName = "${module.asg.this_autoscaling_group_name}"
  }

  alarm_description = "Monitors CPU activity of the Tyk gateway instances for scaling policy"
  alarm_actions     = ["${aws_autoscaling_policy.scale_up.arn}"]
  ok_actions        = ["${aws_autoscaling_policy.scale_down.arn}"]

  count = "${var.create_scaling_policies}"
}
