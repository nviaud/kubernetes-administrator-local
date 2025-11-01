# CKA Training Project Context

## Project Goal
This project is dedicated to preparing for the **Certified Kubernetes Administrator (CKA)** certification exam. The goal is to gain hands-on experience with Kubernetes cluster administration through practical exercises in a realistic environment.

## Infrastructure Setup

### Virtualization Platform
- **Platform**: VirtualBox
- **Purpose**: Local Kubernetes cluster deployment for hands-on practice

### Cluster Architecture
- **1 Control Plane Node**: Manages the Kubernetes cluster
- **2 Worker Nodes**: Run application workloads
- **Total**: 3-node Kubernetes cluster

## Key Components

- **Container Runtime**: containerd
- **CNI Plugin**: Cilium
- **Cluster Management**: kubeadm
- **Kubernetes Version**: v1.31

## Project Scope
This environment will be used to practice CKA exam topics including:
- Cluster installation and configuration
- Workload management
- Services and networking (with Cilium CNI)
- Storage management
- Troubleshooting
- Security best practices
- Cluster maintenance and upgrades

## SSH Access & Remote Administration

### Configuration
- **SSH Keys**: Located in `.ssh/k8s_cluster_key` (in project directory)
- **Authentication**: Key-based (passwordless)
- **User**: `k8s` (all nodes)
- **Passwordless Sudo**: Enabled on all nodes

### Network Details
| Node | Hostname | IP Address | Role |
|------|----------|------------|------|
| VM1 | k8s-control | 192.168.56.10 | Control Plane |
| VM2 | k8s-worker1 | 192.168.56.11 | Worker |
| VM3 | k8s-worker2 | 192.168.56.12 | Worker |

### Using SSH to Administer the Cluster

You can execute commands on cluster nodes directly from Windows PowerShell without logging in:

**Connect to a node:**
```powershell
ssh k8s-control
ssh k8s-worker1
ssh k8s-worker2
```

**Execute remote commands:**
```powershell
# Check cluster status
ssh k8s-control "kubectl get nodes"
ssh k8s-control "kubectl get pods -A"

# Check system services (sudo works without password)
ssh k8s-control "sudo systemctl status kubelet"
ssh k8s-control "sudo journalctl -u kubelet -n 50"

# Execute on all nodes
foreach ($node in @("k8s-control", "k8s-worker1", "k8s-worker2")) {
    ssh $node "uptime"
}
```

**Common administrative patterns:**
```powershell
# Restart kubelet on all nodes
foreach ($node in @("k8s-control", "k8s-worker1", "k8s-worker2")) {
    ssh $node "sudo systemctl restart kubelet"
}

# Check disk usage on all nodes
foreach ($node in @("k8s-control", "k8s-worker1", "k8s-worker2")) {
    Write-Host "`n=== $node ===" -ForegroundColor Cyan
    ssh $node "df -h"
}

# Deploy and manage applications
ssh k8s-control "kubectl apply -f /mnt/shared/my-app.yaml"
ssh k8s-control "kubectl scale deployment my-app --replicas=5"
```

## Notes
- This is a learning environment designed to simulate real-world Kubernetes administration scenarios
- All nodes are virtual machines running in VirtualBox
- The setup follows CKA exam requirements and best practices
- **SSH-based cluster management enables automation and scripting of administrative tasks**
- Files can be shared between Windows host and VMs via `/mnt/shared` directory