# Badges & Live Status

This page shows example badges you can embed on https://ascto.com/ or in the repo README to display CI and ArgoCD status.

GitHub Actions badge (replace OWNER/REPO and workflow filename):

[![CI](https://github.com/OWNER/REPO/actions/workflows/validate-manifests.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/validate-manifests.yml)

ArgoCD application health badge (replace server and app):

[![ArgoCD Health](https://img.shields.io/argocd/health?server=https%3A%2F%2Fargocd.example.com&app=crossplane-control-plane)](https://argocd.example.com/applications/crossplane-control-plane)

How to generate a live badge for ArgoCD

1. Determine your ArgoCD server host (for example `https://argocd.example.com`).
2. Ensure ArgoCD API is reachable and public or accessible from the site that will render the badge.
3. Use the shields.io `argocd` endpoint as shown above, URL-encoding the server.

Notes on security
- Embedding ArgoCD badges that call a private ArgoCD server may leak information if the server is publicly accessible. Use caution and consider proxying or using an authenticated badge service.
