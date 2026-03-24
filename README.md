# **SafeZone Deploy**
[![CI Status](https://img.shields.io/badge/CI-Passing-green?style=for-the-badge)](https://github.com/rebodutch/safezone-deploy/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

The dedicated deployment and infrastructure configuration repository for the **SafeChord** project.

## **🎯 About This Repository (SafeZone-Deploy)**

This repository (SafeZone-Deploy) serves as the **infrastructure & deployment layer** of the SafeChord ecosystem. While the `SafeZone` repository focuses on application logic, this repository handles *how* and *where* that application runs.

> 💡 **Context**: This is part of the larger **SafeChord Ecosystem**. It acts as the bridge, taking the application artifacts from [**SafeZone**](../SafeZone) and deploying them onto the infrastructure platform managed by [**Chorde**](../Chorde).

It embodies the "Production-Grade" mindset by separating configuration from code, ensuring that deployment processes are:

*   **Declarative**: Defined as code (IaC) using Helm and Kubernetes manifests.
*   **Reproducible**: Consistent environments from local preview to production.
*   **Automated**: Tightly integrated with CI/CD pipelines for continuous delivery.

## **✨ Architectural Highlights**

*   **Modular Helm Strategy**: Utilizes a tiered Helm chart architecture (`infra`, `core`, `ui`, `seed`) to decouple infrastructure dependencies (Postgres, Redis, Kafka) from application logic.
*   **Multi-Environment Support**: Structured configurations for `preview`, `staging`, and `production` environments, allowing for safe promotion strategies.
*   **Preview Environment Automation**: specialized workflows (`build-preview`) to dynamically spin up ephemeral environments for Pull Requests.
*   **Bootstrap & RBAC**: Includes tooling for cluster bootstrapping and Role-Based Access Control (RBAC) management, ensuring a secure foundation.

## **💻 Tech Stack**

*   **Orchestration**: Kubernetes
*   **Package Management**: Helm (Umbrella Chart pattern)
*   **CI/CD**: GitHub Actions
*   **Scripting**: Bash (Bootstrap & Utilities)

## **📂 Repository Structure**

*   `helm-charts/`: Custom Helm charts defining the application components.
    *   `safezone-infra`: Foundation services (Databases, Message Brokers).
    *   `safezone-core`: Backend microservices and pipelines.
    *   `safezone-ui`: Frontend dashboard.
    *   `safezone-seed`: Data seeding and initialization.
*   `deploy/`: Environment-specific configurations and overrides.
    *   `preview/`: Ephemeral environments for testing.
    *   `staging/` & `production/`: Stable long-running environments.
*   `bootstrap/`: Scripts and manifests for initial cluster setup.

## **🚀 Quick Start**

To deploy SafeZone to a Kubernetes cluster, ensuring you have `kubectl` and `helm` installed:

### **1. Bootstrap Cluster**

Initialize your cluster with necessary permissions and base configurations (refer to `bootstrap/README.md` if available, or inspect scripts):

```bash
# Example usage (refer to actual scripts for details)
./bootstrap/scripts/gen-kubeconfig.sh
```

### **2. Deploy with Helm**

Navigate to the specific environment or chart you wish to deploy. For example, to deploy the core services:

```bash
helm install safezone-core ./helm-charts/safezone-core
```

*(Note: Specific deployment commands may vary based on the target environment configuration in `deploy/`)*

## **📄 License**

This project is licensed under the MIT License. See the LICENSE file for details.
