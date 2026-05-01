# Terraform Best Practices

## Project Structure

- Keep environments separate.
- Put reusable logic in modules.
- Keep variables explicit and typed.
- Keep outputs useful but not noisy.
- Do not put secrets in `.tfvars` files committed to Git.

## State

- Use remote state for team projects.
- Enable state locking.
- Never manually edit state unless there is a documented recovery reason.
- Back up state before state surgery.
- Do not commit `terraform.tfstate` files for real projects.

## Naming and Tags

- Use predictable names: `<project>-<environment>-<component>`.
- Require `environment`, `owner`, `cost_center`, and `managed_by` tags.
- Keep names short enough for cloud provider limits.

## Workflow

- Run `terraform fmt -recursive`.
- Run `terraform validate`.
- Review `terraform plan` before every apply.
- Save plans in CI/CD when approval is required.
- Avoid `-target` except for recovery or advanced maintenance.

## Modules

- Pin external module versions.
- Prefer small modules with clear ownership.
- Document inputs and outputs.
- Avoid hidden provider configuration inside reusable modules.

## Security

- Store secrets in a secret manager.
- Mark sensitive outputs as `sensitive = true`.
- Use least-privilege credentials for Terraform.
- Run policy checks before apply.
- Keep provider lock files under review.
