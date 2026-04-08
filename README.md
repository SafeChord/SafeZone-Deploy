# **SafeZone Deploy**
[![CI Status](https://img.shields.io/badge/CI-Passing-green?style=for-the-badge)](https://github.com/SafeChord/SafeZone-Deploy/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> ⚠️ **Soak Testing in Progress**: The `staging` branch is currently undergoing soak testing (v0.2.1). This `main` branch will be updated upon successful completion.

The dedicated deployment and infrastructure configuration repository for the **SafeChord** project.

## **🎯 About This Repository**

SafeZone-Deploy is the **delivery layer** of the SafeChord ecosystem. It takes application artifacts from [**SafeZone**](../SafeZone) and declares *how* and *where* they run on the infrastructure platform managed by [**Chorde**](../Chorde).

Deployment is fully **GitOps-driven**: every push to this repository is picked up by ArgoCD and reconciled against the live cluster. There is no manual `helm install`.

## **✨ Architectural Highlights**

- **Modular Helm Charts**: Tiered chart architecture (`foundation`, `core`, `ui`, `seed`) decouples infrastructure dependencies from application logic.
- **Multi-Environment Support**: Separate configurations for `preview` (ephemeral, PR-scoped) and `staging` (persistent, soak-test target).
- **GitOps via ArgoCD**: All environments are managed as ArgoCD Applications. Sync is automatic on commit.
- **Sealed Secrets**: All secrets are encrypted via Bitnami Sealed Secrets before committing. Plaintext lives only in `unsealed/` (gitignored).
- **Daily Simulation Scheduler**: Staging runs a CronJob (`safezone-scheduler`) that simulates one new day of data per day, driven by the time-server's system date.

## **💻 Tech Stack**

- **Orchestration**: Kubernetes (K3s)
- **Package Management**: Helm
- **GitOps**: ArgoCD
- **CI/CD**: GitHub Actions (`init-deploy.yml`)
- **Secrets Management**: Bitnami Sealed Secrets

## **📂 Repository Structure**

```
helm-charts/
  safezone-common/      # Shared Helm helpers (_helpers.tpl)
  safezone-foundation/  # Foundation layer: cli-relay, time-server, ingress, configmap
  safezone-core/        # Core layer: analytics-api, ingestor, simulator, worker
  safezone-ui/          # UI layer: dashboard
  safezone-seed/        # Seed jobs (one-shot) and daily simulation CronJob

deploy/
  preview/              # Ephemeral PR sandbox environments
  staging/              # Persistent staging environment (Chorde PaaS)
    app/                # ArgoCD Application manifests
    infra/              # Namespace, RBAC, secrets, workloads

scripts/
  ops/
    gen-kubeconfig.sh   # Generate low-privilege kubeconfig for CI
    seal-secrets.sh     # Seal all unsealed secrets for an environment
    staging/            # Manual staging ops (setup, teardown, verify)
    preview/            # Manual preview ops (setup, teardown, verify)
```

## **🚀 Deployment**

### Staging (GitOps)

Staging is managed entirely via ArgoCD. To deploy or update:

```bash
# Trigger via GitHub Actions (recommended)
# → Actions → "Deploy App Layer" → environment: staging

# Or apply ArgoCD Applications directly
kubectl apply -f deploy/staging/infra/application.yaml
kubectl apply -f deploy/staging/app/
```

### Sealing Secrets

After editing any file in `deploy/<env>/infra/security/unsealed/`:

```bash
bash scripts/ops/seal-secrets.sh staging
# commit the updated sealed-*.yaml files
```

## **📄 License**

This project is licensed under the MIT License.
