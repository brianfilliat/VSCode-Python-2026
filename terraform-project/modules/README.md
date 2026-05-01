# Modules Layer

Modules are reusable Terraform building blocks. Environments should call modules instead of duplicating resource definitions.

## Current Module

- `local-project/` creates local training artifacts for an environment.

## Module Rules

- Keep modules environment-neutral.
- Pass environment-specific values through variables.
- Add `variables.tf`, `outputs.tf`, and a module `README.md`.
- Do not hard-code account IDs, regions, secrets, or environment names.
- Prefer small modules with one clear responsibility.
