output "cloud_config" {
  value       = "${data.template_file.cloudwatch_cloud_config.rendered}"
  description = "Rendered cloud config file to include for CloudWatch agent installation and configuration"
}
