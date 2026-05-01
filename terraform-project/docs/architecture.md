# Terraform Project Architecture

This repo uses a layered Terraform structure.

## 1. Environments Layer

`environments/dev`, `environments/stage`, and `environments/prod` are root modules. A root module is the folder where Terraform commands run.

Each environment owns:

- provider requirements
- module calls
- variables
- outputs
- environment-specific `.tfvars`
- state for that environment

In production, each environment usually has its own remote backend state key.

## 2. Module Layer

`modules/local-project` is reusable logic. It receives inputs from each environment and produces repeatable outputs.

Modules should answer one question: "What building block do I create?" Environments answer: "Where and with what settings do I create it?"

## 3. Provider Layer

Providers are plugins that let Terraform talk to an API. This project uses `hashicorp/local` for safe training. Real projects may use `aws`, `azurerm`, `google`, `kubernetes`, or other providers.

## 4. Policy Layer

Policies check plans before apply. They are most useful in CI/CD, where a pull request can fail early if it violates guardrails.

## 5. Scripts Layer

Scripts make Terraform commands consistent across learners and teams. They are not a replacement for understanding Terraform; they are a reliable wrapper around the workflow.

## Recommended Promotion Flow

1. Develop in `dev`.
2. Review the plan output.
3. Promote the same module version and variable pattern to `stage`.
4. Test and validate.
5. Promote to `prod` with approval.
