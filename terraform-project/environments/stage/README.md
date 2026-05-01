# Stage Environment

Use this environment to practice promotion from `dev` before production.

```powershell
.\scripts\init.ps1 -Environment stage
.\scripts\validate.ps1 -Environment stage
.\scripts\plan.ps1 -Environment stage
```
