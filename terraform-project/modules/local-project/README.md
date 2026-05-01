# local-project Module

This module creates local files that represent environment-specific infrastructure output. It is intentionally safe for training because it uses the `local` provider instead of a cloud provider.

## Inputs

- `project_name`: project identifier
- `environment`: environment name
- `owner`: responsible team or person
- `cost_center`: chargeback or tracking code
- `sample_message`: message written to the sample file
- `tags`: common metadata map

## Outputs

- `sample_file_path`
- `metadata_file_path`
- `project_context`

## Training Goal

Students should trace how values move from `environments/dev/terraform.tfvars` into this module and then into generated files under `outputs/dev/`.
