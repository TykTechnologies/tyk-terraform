# Tyk Terraform modules and examples

This repository contains Terraform modules to deploy Tyk components on supported platforms (currently only AWS but more to come).

See more at:
 * [Gateway on AWS](modules/tyk-gateway/aws/)
 * [Dashboard on AWS](modules/tyk-dashboard/aws/)
 * [Pump on AWS](modules/tyk-pump/aws/)
 * [MDCB on AWS](modules/tyk-mdcb/aws/)
 * [AWS CloudWatch logs and metrics for Tyk](modules/tyk-metrics/cloudwatch)

Full deployment examples are available in the deployments directory.

## Compatibility
These modules were written for Terraform version 0.11. Version 0.12 has backwards incompatible syntax and may not work without modifications. Migration to Terraform 0.12+ is planned, see #2.
