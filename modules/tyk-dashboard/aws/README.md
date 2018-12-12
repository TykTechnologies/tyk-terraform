# Tyk Dashboard on AWS Terraform module

Terraform module which creates AWS resources for Tyk Dashboard.

This module includes the following components:
 * Security groups for LB and instances
 * Application Load Balancer for dashboard instances, with target groups, listeners and health checks
 * Launch configuration for dashboard instances based on latest Amazon Linux 2 AMI and official tyk-dashboard package
 * Auto-scaling group that utilises the launch configuration and LB target groups for fault-tolerance and zero-downtime deployments
 * Optional scaling policies based on LB target group latency

## Usage

```hcl
module "tyk_dashboard" {
  source = "modules/tyk-dashboard/aws"

  vpc_id                  = "vpc-a123f4da"
  instance_subnets        = ["subnet-012345c34d32a4ca9", "subnet-5432108982f9ca6c3"]
  lb_subnets              = ["subnet-1cfbde23", "subnet-326ab10e"]
  ssh_sg_id               = "sg-0f12c3fb044629789"
  key_name                = "ssh-key-name"
  redis_host              = "some.redis"
  redis_port              = "6379"
  redis_password          = "secret"
  mongo_url               = "mongodb://user:password@cluster0-shard-00-00.mongo:27017,cluster0-shard-00-01.mongo:27017,cluster0-shard-00-02.mongo:27017/tyk?replicaSet=Cluster0-shard-0"
  mongo_use_ssl           = "true"
  license_key             = "tyk license here"
  instance_type           = "t3.medium"
  min_size                = 2
  max_size                = 4
  create_scaling_policies = true
  port                    = "80"
  notifications_port      = "5000"
  dashboard_version       = "1.7.3"
  gateway_host            = "gw.host"
  gateway_port            = "80"
  gateway_secret          = "supersecret1"
  shared_node_secret      = "supersecret2"
  admin_secret            = "supersecret3"
  hostname                = "admin.host"
  api_hostname            = "gw.host"
  portal_root             = "/portal"
}
```

This example will create a launch configuration with `tyk-dashboard-1.7.3` running on `t3.medium`  instances in VPC subnets "subnet-012345c34d32a4ca9" and "subnet-5432108982f9ca6c3" accessible on port 80 (and 5000 for notifications), connected to Redis and MongoDB via specified configurations.

The auto-scaling group will have between 2 and 4 instances with default scaling policies created too.

The load balancer will be provisioned in VPC subnets "subnet-012345c34d32a4ca9" and "subnet-5432108982f9ca6c3".

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| admin\_secret | Tyk dashboard admin API secret | string | `` | no |
| api\_hostname | API hostname | string | `` | no |
| create\_scaling\_policies | Create scaling policies and alarm for autoscaling group | string | `false` | no |
| dashboard\_config | Full dashboard config file contents (replaces the default config file if set) | string | `` | no |
| dashboard\_version | Version of Tyk dashboard to deploy | string | - | yes |
| gateway\_host | Tyk gateway host | string | `` | no |
| gateway\_port | Tyk gateway port | string | `` | no |
| gateway\_secret | Tyk gateway secret | string | `` | no |
| hostname | Tyk dashboard hostname | string | `` | no |
| ingress\_cidr | CIDR of ingress source | string | `0.0.0.0/0` | no |
| instance\_subnets | List of subnets to use for instances | list | - | yes |
| instance\_type | EC2 instance type | string | `c5.large` | no |
| key\_name | EC2 key pair name | string | - | yes |
| lb\_subnets | List of subnets to use for load balancing | list | - | yes |
| license\_key | Tyk license | string | `` | no |
| max\_size | Maximum number of instance in autoscaling group | string | `2` | no |
| min\_size | Minimum number of instances in autoscaling group | string | `1` | no |
| mongo\_url | MongoDB connection string | string | `` | no |
| mongo\_use\_ssl | Should MongoDB connection use SSL/TLS? | string | `` | no |
| notifications\_port | Notifications service port | string | `5000` | no |
| port | HTTP port of the dashboard | string | `80` | no |
| portal\_root | Tyk dashboard portal root path | string | `` | no |
| redis\_enable\_cluster | Is Redis clustering enabled? | string | `` | no |
| redis\_host | Redis host | string | `` | no |
| redis\_hosts | Redis cluster connection parameters | string | `` | no |
| redis\_password | Redis password | string | `` | no |
| redis\_port | Redis port | string | `` | no |
| shared\_node\_secret | Shared gateway-dashboard secret for API definitions | string | `` | no |
| ssh\_sg\_id | Security group for SSH access | string | `` | no |
| vpc\_id | VPC to use for Tyk dashboard | string | - | yes |

## Outputs

 Name | Description |
|------|-------------|
| asg\_arn | ARN of the auto-scaling group |
| asg\_name | Name of the auto-scaling group |
| dns\_name | Domain name of the load balancer |
| instance\_profile\_name | Name of the IAM instance profile |
| instance\_role\_name | Name of the IAM instance role |
| lb\_id | ID of the load balancer |
| lb\_sg\_id | ID of the load balancer security group |
| sg\_id | ID of the instances security group |
| zone\_id | ID of the load balancer domain zone |
