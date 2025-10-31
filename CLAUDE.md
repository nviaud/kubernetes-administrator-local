# CKA Training Project Context

## Project Goal
Training and preparation for the **Certified Kubernetes Administrator (CKA)** certification exam.

## Infrastructure Setup

### Virtualization Platform
- **Platform**: VirtualBox
- **Purpose**: Local Kubernetes cluster deployment for hands-on practice

### Cluster Architecture
- **Cluster Type**: Multi-node Kubernetes cluster
- **Total Nodes**: 3

#### Node Configuration
1. **Control Plane Node**: 1
   - Manages the Kubernetes cluster
   - Runs control plane components (API server, scheduler, controller manager, etcd)

2. **Worker Nodes**: 2
   - Run containerized applications
   - Execute workloads assigned by the control plane

## Project Scope
This environment will be used to practice CKA exam topics including:
- Cluster installation and configuration
- Workload management
- Services and networking
- Storage management
- Troubleshooting
- Security best practices
- Cluster maintenance and upgrades

## Notes
- This is a learning environment designed to simulate real-world Kubernetes administration scenarios
- All nodes will be virtual machines running in VirtualBox
- The setup follows CKA exam requirements and best practices