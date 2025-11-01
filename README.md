# CKA Training Environment

A local Kubernetes cluster setup for Certified Kubernetes Administrator (CKA) exam preparation.

## Overview

3-node Kubernetes cluster running on VirtualBox:
- 1 Control Plane node
- 2 Worker nodes
- Kubernetes v1.33.1
- Cilium CNI
- Ubuntu Server 24.04 LTS

## Quick Start

### Prerequisites
- VirtualBox installed
- Windows 10/11 with PowerShell
- 8GB RAM available
- 50GB disk space

### Installation

1. **Provision VMs:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File provision-vms.ps1
   ```

2. **Follow the installation procedure:**
   See `INSTALLATION_PROCEDURE_WINDOWS.md` for detailed setup instructions.

## Cluster Access

### SSH to Nodes
```powershell
ssh k8s-control
ssh k8s-worker1
ssh k8s-worker2
```

### Remote Commands
```powershell
# Check cluster status
ssh k8s-control "kubectl get nodes"

# Run on all nodes
foreach ($node in @("k8s-control", "k8s-worker1", "k8s-worker2")) {
    ssh $node "uptime"
}
```

## Cluster Information

| Node | IP Address | Role |
|------|------------|------|
| k8s-control | 192.168.56.10 | Control Plane |
| k8s-worker1 | 192.168.56.11 | Worker |
| k8s-worker2 | 192.168.56.12 | Worker |

**Network:**
- Host-Only: 192.168.56.0/24
- Pod Network: 192.168.0.0/16
- Service Network: 10.96.0.0/12

## Management

### Start Cluster
```powershell
VBoxManage startvm k8s-control --type headless
VBoxManage startvm k8s-worker1 --type headless
VBoxManage startvm k8s-worker2 --type headless
```

### Stop Cluster
```powershell
VBoxManage controlvm k8s-control poweroff
VBoxManage controlvm k8s-worker1 poweroff
VBoxManage controlvm k8s-worker2 poweroff
```

## Tools Installed

- **kubectl** - Kubernetes CLI
- **kubeadm** - Cluster management
- **HELM** - Package manager
- **K9S** - Terminal UI for Kubernetes
- **containerd** - Container runtime
- **Cilium** - eBPF-based CNI

## Project Structure

```
.
├── README.md                           # This file
├── INSTALLATION_PROCEDURE_WINDOWS.md   # Complete setup guide
├── provision-vms.ps1                   # VM provisioning script
├── cluster-config/                     # Cluster configuration files
│   ├── kubeadm-config.yaml            # Kubeadm init configuration
│   └── cilium-cni.yaml                # Cilium CNI manifest
├── docs/                               # Documentation
└── .ssh/                               # SSH keys for cluster access
```

## Credentials

- **Username:** `k8s`
- **Password:** `k8s`
- **SSH:** Key-based (`.ssh/k8s_cluster_key`)

## Training Resources

This environment is designed for practicing CKA exam topics:
- Cluster installation and configuration
- Workload management
- Networking and services
- Storage management
- Security and RBAC
- Troubleshooting
- Cluster maintenance

## Notes

- This is a **local training environment** - not for production use
- SSH keys are committed to the repository for convenience
- Shared folder available at `/mnt/shared` on all VMs
- Take snapshots before major changes

## License

For personal CKA training and educational purposes.
