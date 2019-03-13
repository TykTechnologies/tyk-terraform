data "template_file" "rsyslog_config" {
  template = "${file("${path.module}/rsyslog_config.conf")}"

  vars {
    program = "${var.program_name}"
  }
}

data "template_file" "logrotate_config" {
  template = "${file("${path.module}/logrotate_config.conf")}"

  vars {
    program = "${var.program_name}"
  }
}

data "template_file" "cloudwatch_config" {
  template = "${file("${path.module}/cloudwatch_config.json")}"

  vars {
    program          = "${var.program_name}"
    log_group_prefix = "${var.log_group_prefix}"
    namespace        = "${var.metrics_namespace}"
  }
}

data "template_file" "cloudwatch_cloud_config" {
  template = "${file("${path.module}/cloud_config.yml")}"

  vars {
    cloudwatch_config = "${base64encode("${data.template_file.cloudwatch_config.rendered}")}"
    rsyslog_config    = "${base64encode("${data.template_file.rsyslog_config.rendered}")}"
    logrotate_config  = "${base64encode("${data.template_file.logrotate_config.rendered}")}"
    program           = "${var.program_name}"
  }
}
