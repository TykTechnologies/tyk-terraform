# AWS CloudWatch metrics and logs for Tyk Terraform module

This Terraform module creates cloud-init configuration to stream application logs into CloudWatch Logs, collect application's statsd and general OS metrics with a unified CloudWatch Agent.

The output can be used as a part in a multi-part `template_cloudinit_config` Terraform data object.

**NOTE**: Pushing logs and metrics to AWS CloudWatch requires the instance to have the `arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy` policy attached to its instance role.

## Usage

```hcl
module "tyk_cloudwatch_gateway" {
  source = "modules/tyk-metrics/cloudwatch"

  program_name      = "tyk"
  log_group_prefix  = "tyk-pro-us-east-1"
  metrics_namespace = "TykGateway"
}
```

The output of that is compatible with `metrics_cloudconfig` varible of all the Tyk components:

```hcl
module "tyk_gateway" {
  source = "modules/tyk-gateway/aws"

  ...
  enable_cloudwatch_policy = true
  metrics_cloudconfig      = module.tyk_cloudwatch_gateway.cloud_config
  statsd_conn_str          = "localhost:8125"
  statsd_prefix            = "us-east-1.tykGateway"
  ...
```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| log\_group\_prefix | CloudWatch Logs group name prefix | string | `tyk` | no |
| metrics\_namespace | Namespace for custom metrics | string | `TykMetrics` | no |
| program\_name | Program name to filter the logs by | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloud\_config | Rendered cloud config file to include for CloudWatch agent installation and configuration |
