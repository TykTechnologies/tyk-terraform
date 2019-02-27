## Security groups

resource "aws_security_group" "instance_sg" {
  name   = "tyk_pump_instance"
  vpc_id = "${var.vpc_id}"

  # "allow all" egress rule is fine for instances too as they need outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
    repository           = "${var.package_repository}"
    pump_version         = "${var.pump_version}"
    custom_config        = "${base64encode("${var.pump_config}")}"
    mongo_url            = "${var.mongo_url}"
    mongo_use_ssl        = "${var.mongo_use_ssl}"
    redis_host           = "${var.redis_host}"
    redis_port           = "${var.redis_port}"
    redis_password       = "${var.redis_password}"
    redis_enable_cluster = "${var.redis_enable_cluster}"
    redis_hosts          = "${var.redis_hosts}"
  }
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "tyk_pump"

  # Launch configuration
  lc_name              = "tyk_pump"
  image_id             = "${data.aws_ami.amazonlinux.id}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.instance_sg.id}", "${var.ssh_sg_id}"]
  key_name             = "${var.key_name}"
  user_data            = "${data.template_file.cloud_config.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.default.name}"

  root_block_device = [
    {
      volume_size = "10"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                     = "tyk_pump"
  vpc_zone_identifier          = ["${var.instance_subnets}"]
  health_check_type            = "EC2"
  min_size                     = "${var.min_size}"
  max_size                     = "${var.max_size}"
  desired_capacity             = "${var.min_size}"
  wait_for_capacity_timeout    = "5m"
  recreate_asg_when_lc_changes = true                        # Enables Blue/Green deployments, TODO: possibly marry CloudFormation for rolling upgrades
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "tyk_pump_scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${module.asg.this_autoscaling_group_name}"

  count = "${var.create_scaling_policies}"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "tyk_pump_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${module.asg.this_autoscaling_group_name}"

  count = "${var.create_scaling_policies}"
}

resource "aws_cloudwatch_metric_alarm" "scaling_alarm" {
  alarm_name          = "tyk_pump_scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
    AutoScalingGroupName = "${module.asg.this_autoscaling_group_name}"
  }

  alarm_description = "Monitors CPU activity of the Tyk pump instances for scaling policy"
  alarm_actions     = ["${aws_autoscaling_policy.scale_up.arn}"]
  ok_actions        = ["${aws_autoscaling_policy.scale_down.arn}"]

  count = "${var.create_scaling_policies}"
}
