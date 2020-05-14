# Tyk Pump on AWS Terraform module

Terraform module which creates AWS resources for Tyk Pump.

This module includes the following components:
 * Launch configuration for pump instances based on latest Amazon Linux 2 AMI and official tyk-pump package
 * Auto-scaling group that utilises the launch configuration for fault-tolerance and zero-downtime deployments
 * Optional scaling policies based on group's CPU utilisation

## Usage

```hcl
module "tyk_pump" {
  source = "modules/tyk-pump/aws"

  vpc_id                    = "vpc-a123f4da"
  instance_subnets          = ["subnet-012345c34d32a4ca9", "subnet-5432108982f9ca6c3"]
  ssh_sg_id                 = "sg-0f12c3fb044629789"
  key_name                  = "ssh-key-name"
  redis_host                = "some.redis"
  redis_port                = "6379"
  redis_password            = "secret"
  mongo_url                 = "mongodb://user:password@cluster0-shard-00-00.mongo:27017,cluster0-shard-00-01.mongo:27017,cluster0-shard-00-02.mongo:27017/tyk?replicaSet=Cluster0-shard-0"
  mongo_use_ssl             = "true"
  instance_type             = "t3.large"
  min_size                  = 2
  max_size                  = 4
  create_scaling_policies   = true
  pump_version              = "0.8.4"
}
```

This example will create a launch configuration with `tyk-pump-0.8.4` running on `t3.large`  instances in VPC subnets "subnet-012345c34d32a4ca9" and "subnet-5432108982f9ca6c3", connected to Redis and MongoDB via specified configurations.

The auto-scaling group will have between 2 and 4 instances with default scaling policies created too.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| create\_scaling\_policies | Create scaling policies and alarm for autoscaling group | string | `false` | no |
| enable\_cloudwatch\_policy | Enable CloudWatch agent IAM policy for the instance profile | string | `false` | no |
| enable\_ssm | Enable AWS Systems Manager | string | `false` | no |
| instance\_subnets | List of subnets to use for instances | list | - | yes |
| instance\_type | EC2 instance type | string | `c5.large` | no |
| key\_name | EC2 key pair name | string | - | yes |
| max\_size | Maximum number of instance in autoscaling group | string | `2` | no |
| metrics\_cloudconfig | Rendered cloud-init config for metrics and logs collection setup | string | `` | no |
| min\_size | Minimum number of instances in autoscaling group | string | `1` | no |
| mongo\_url | MongoDB connection string | string | `` | no |
| mongo\_use\_ssl | Should MongoDB connection use SSL/TLS? | string | `` | no |
| package\_repository | Repository name for the PackageCloud package | string | `tyk-pump` | no |
| pump\_config | Full pump config file contents (replaces the default config file if set) | string | `` | no |
| pump\_version | Version of Tyk pump to deploy | string | - | yes |
| redis\_enable\_cluster | Is Redis clustering enabled? | string | `` | no |
| redis\_host | Redis host | string | `` | no |
| redis\_hosts | Redis cluster connection parameters | string | `` | no |
| redis\_password | Redis password | string | `` | no |
| redis\_port | Redis port | string | `` | no |
| ssh\_sg\_id | Security group for SSH access | string | `` | no |
| statsd\_conn\_str | Connection string for statsd instrumentation | string | `` | no |
| statsd\_prefix | Prefix for statsd metrics | string | `tykPMP` | no |
| vpc\_id | VPC to use for Tyk pump | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| asg\_arn | ARN of the auto-scaling group |
| asg\_name | Name of the auto-scaling group |
| instance\_profile\_name | Name of the IAM instance profile |
| instance\_role\_name | Name of the IAM instance role |
