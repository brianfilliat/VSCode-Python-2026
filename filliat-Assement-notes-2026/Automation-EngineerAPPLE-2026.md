### APPLE interview
###Automation-Engineer-2026.md####
#### Automation Engineer (Infrastructure as Code – Data Services)
###  update D:\DOCU-2026\Python-vscode-2026\filliat-Assement-notes-2026\Automation-Engineer-2026.md
###    do not merge
####  ALWAYS insert PATH into the notes section 
#### D:\DOCU-2026\Python-vscode-2026\filliat-Assement-notes-2026
#####






### Required Qualifications

- Strong experience as an AWS Cloud Engineer, Automation Engineer, or Infrastructure Engineer.
- Hands-on experience with Infrastructure as Code (IaC) frameworks such as:
  - Terraform
  - CloudFormation
  - Similar IaC frameworks (e.g., Pulumi, Terragrunt)
- Proficiency in Python for automation and scripting.
- Practical experience working with AWS managed data services, such as:
  - Amazon Aurora
  - DynamoDB
  - Cassandra (managed or self-hosted)
  - Other AWS-managed databases and data stores.
- Ability to translate data service requirements into automated, repeatable infrastructure solutions (templated IaC modules, parameterized stacks, CI/CD).

<!-- Path: D:\DOCU-2026\Python-vscode-2026\filliat-Assement-notes-2026\Automation-Engineer-2026.md -->

**Related resources:** sample Terraform module: `filliat-Assement-notes-2026/terraform/managed-db-module` and CI workflow at `.github/workflows/terraform-managed-db-ci.yml`.

## Exported Session

- Date: 2026-02-15
- Summary: session edits and additions performed by the assistant; below are actions and changed files for traceability.

### Actions performed

- Updated `Data-Engineer-BairesDev-2026.md` with a concise summary, core qualifications, a one-page resume section, and STAR-format achievement bullets.
- Inserted Required Qualifications into `Automation-Engineer-2026.md` (IaC, Python, AWS managed data services, translation to repeatable infra).
- Added a sample Terraform module for a managed Aurora DB (subnet group, SG, optional Secrets Manager secret, cluster + instances), example usage, and README.
- Added a GitHub Actions CI workflow to run `terraform fmt`, `init`, `validate`, `plan`, `tfsec`, and tflint for the module.
- Updated `Automation-Engineer-2026.md` to reference the new module and CI workflow.

### Files added/modified

- `filliat-Assement-notes-2026/Data-Engineer-BairesDev-2026.md` (updated)
- `filliat-Assement-notes-2026/Automation-Engineer-2026.md` (updated)
- `filliat-Assement-notes-2026/terraform/managed-db-module/main.tf` (added)
- `filliat-Assement-notes-2026/terraform/managed-db-module/variables.tf` (added)
- `filliat-Assement-notes-2026/terraform/managed-db-module/outputs.tf` (added)
- `filliat-Assement-notes-2026/terraform/managed-db-module/README.md` (added)
- `filliat-Assement-notes-2026/terraform/managed-db-module/examples/usage/main.tf` (added)
- `filliat-Assement-notes-2026/.github/workflows/terraform-managed-db-ci.yml` (added)

If you want this exported session saved to a separate file or committed to git with a message, I can do that next.
