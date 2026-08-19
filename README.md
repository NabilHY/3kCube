# 3kCube / Inception-of-Things Project

A project that served as an introduction to IaC, containerization technologies, and CD/GitOps.

Wasn't hard, but the learning curve was real. I'll be writing a README for each subdirectory; the structure is as follows, and each part builds the knowledge needed for the one that follows:

- **Part 1**: Vagrant — IaC, container networking, providers, provisioning, and K3s installation.
- **Part 2**: Provisioning a machine and using the K3s CLI, applying manifests, building a standard cluster environment — K8s basics like ingress, deployments, services, and their basic setup.
- **Part 3**: Building a full GitOps/CD pipeline that takes a Git repo as the source of truth to deploy stuff locally.
- **Bonus**: Same as Part 3, except you switch the remote Git repo for one of your own, hosted locally — Gitea was used for that.

I'll be covering each part in depth for documentation purposes, as this project is a good starting point to delve into CI/CD and DevOps tools — although definitely not enough on its own, so feel free to look around further.

> **NB**: switching from GitLab to Gitea for the bonus was a decision made by the educational team — GitLab was too resource-heavy, so Gitea was chosen instead for resource reasons.
