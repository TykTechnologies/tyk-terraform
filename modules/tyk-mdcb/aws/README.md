# Tyk MDCB on AWS Terraform module

Terraform module which creates AWS resources for Tyk MDCB.

This module includes the following components:
 * Security group for instances
 * Network Load Balancer for MDCB instances, with target group, listeners and health checks
 * Launch configuration for MDCB instances based on latest Amazon Linux 2 AMI and official tyk-sink package
 * Auto-scaling group that utilises the launch configuration and LB target groups for fault-tolerance and zero-downtime deployments
 * Optional scaling policies based on group's CPU utilisation

## Usage

```hcl
module "tyk_mdcb" {
  source = "modules/tyk-mdcb/aws"

  vpc_id                    = "vpc-a123f4da"
  instance_subnets          = ["subnet-012345c34d32a4ca9", "subnet-5432108982f9ca6c3"]
  lb_subnets                = ["subnet-1cfbde23", "subnet-326ab10e"]
  ssh_sg_id                 = "sg-0f12c3fb044629789"
  key_name                  = "ssh-key-name"
  redis_host                = "some.redis"
  redis_port                = "6379"
  redis_password            = "secret"
  mongo_url                 = "mongodb://user:password@cluster0-shard-00-00.mongo:27017,cluster0-shard-00-01.mongo:27017,cluster0-shard-00-02.mongo:27017/tyk?replicaSet=Cluster0-shard-0"
  mongo_use_ssl             = "true"
  license_key               = "tyk MDCB license here"
  instance_type             = "c5.large"
  port                      = "9090"
  min_size                  = 2
  max_size                  = 4
  create_scaling_policies   = true
  mdcb_version              = "1.5.7"
  forward_to_pump           = "true"
}
```

This example will create a launch configuration with `tyk-sink-1.5.7` running on `c5.large`  instances in VPC subnets "subnet-012345c34d32a4ca9" and "subnet-5432108982f9ca6c3" accessible on port 9090, connected to Redis and MongoDB via specified configurations and forwarding analytics to Tyk Pump.

The auto-scaling group will have between 2 and 4 instances with default scaling policies created too.

The network load balancer will be provisioned in VPC subnets "subnet-012345c34d32a4ca9" and "subnet-5432108982f9ca6c3" along with a TCP listener and HTTP health check.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| create\_scaling\_policies | Create scaling policies and alarm for autoscaling group | string | `false` | no |
| enable\_ssm | Enable AWS Systems Manager | string | `false` | no |
| forward\_to\_pump | Forward analytics to Tyk pump | string | `` | no |
| ingress\_cidr | CIDR of ingress source | string | `0.0.0.0/0` | no |
| instance\_subnets | List of subnets to use for instances | list | - | yes |
| instance\_type | EC2 instance type | string | `c5.large` | no |
| key\_name | EC2 key pair name | string | - | yes |
| lb\_subnets | List of subnets to use for load balancing | list | - | yes |
| license\_key | Tyk MDCB license | string | `` | no |
| max\_size | Maximum number of instance in autoscaling group | string | `2` | no |
| mdcb\_config | Full MDCB config file contents (replaces the default config file if set) | string | `` | no |
| mdcb\_token | Repository token for MDCB packages | string | - | yes |
| mdcb\_version | Version of Tyk MDCB to deploy | string | - | yes |
| min\_size | Minimum number of instances in autoscaling group | string | `1` | no |
| mongo\_url | MongoDB connection string | string | `` | no |
| mongo\_use\_ssl | Should MongoDB connection use SSL/TLS? | string | `` | no |
| package\_repository | Repository name for the PackageCloud package | string | `tyk-mdcb` | no |
| port | Ingress port of the MDCB | string | `9090` | no |
| redis\_enable\_cluster | Is Redis clustering enabled? | string | `` | no |
| redis\_host | Redis host | string | `` | no |
| redis\_hosts | Redis cluster connection parameters | string | `` | no |
| redis\_password | Redis password | string | `` | no |
| redis\_port | Redis port | string | `` | no |
| ssh\_sg\_id | Security group for SSH access | string | `` | no |
| vpc\_id | VPC to use for Tyk MDCB | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| asg\_arn | ARN of the auto-scaling group |
| asg\_name | Name of the auto-scaling group |
| dns\_name | Domain name of the load balancer |
| instance\_profile\_name | Name of the IAM instance profile |
| instance\_role\_name | Name of the IAM instance role |
| lb\_id | ID of the load balancer |
| sg\_id | ID of the instances security group |
| zone\_id | ID of the load balancer domain zone |
