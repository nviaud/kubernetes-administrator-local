# Kernel Networking Parameters for Kubernetes

## Overview

Kubernetes requires specific kernel networking parameters to be configured for proper cluster networking functionality. These parameters are **mandatory prerequisites** that must be set on all nodes (control plane and workers) before initializing the cluster.

## Required Parameters

### 1. net.bridge.bridge-nf-call-iptables

```bash
net.bridge.bridge-nf-call-iptables = 1
```

**Purpose**: Enables iptables processing for bridged IPv4 network traffic

**Why It's Required**:
- Container network traffic passes through Linux network bridges
- This setting ensures bridged packets are sent to iptables for processing
- Enables kube-proxy to apply iptables rules for Services and load balancing
- Required for Kubernetes Network Policies to function correctly

**Without This Setting**:
- Service ClusterIP routing may fail
- Pod-to-pod communication across nodes may break
- Network policies won't be enforced
- Load balancing to Service endpoints won't work

---

### 2. net.bridge.bridge-nf-call-ip6tables

```bash
net.bridge.bridge-nf-call-ip6tables = 1
```

**Purpose**: Enables iptables processing for bridged IPv6 network traffic

**Why It's Required**:
- Same functionality as `bridge-nf-call-iptables` but for IPv6
- Necessary for dual-stack or IPv6-only Kubernetes clusters
- Best practice to enable even if not currently using IPv6

**Without This Setting**:
- IPv6 pod networking will fail
- Dual-stack clusters won't function properly

---

### 3. net.ipv4.ip_forward

```bash
net.ipv4.ip_forward = 1
```

**Purpose**: Enables IP packet forwarding at the kernel level

**Why It's Required**:
- Allows the Linux kernel to forward packets between network interfaces
- Essential for nodes to act as routers for container traffic
- Enables cross-node pod-to-pod communication
- Required by CNI plugins (Cilium, Calico, Flannel, etc.) to route traffic

**Without This Setting**:
- Pods on different nodes cannot communicate
- Nodes cannot forward traffic for containers
- Cluster networking completely breaks

---

## How Kubernetes Networking Uses These Parameters

```
┌─────────────────────────────────────────────────────────────┐
│                    Network Flow Example                      │
└─────────────────────────────────────────────────────────────┘

Pod A (10.244.1.5)              Service VIP              Pod B (10.244.2.8)
   on Node 1                   (10.96.0.10)                 on Node 2
       │                             │                           │
       │ (1) Send to Service IP      │                           │
       ├─────────────────────────────▶                           │
       │                             │                           │
       │ (2) Bridge intercepts       │                           │
       ▼                             │                           │
 [Linux Bridge]                      │                           │
       │                             │                           │
       │ bridge-nf-call-iptables=1   │                           │
       ▼                             │                           │
 [iptables/Netfilter]                │                           │
       │                             │                           │
       │ (3) DNAT to Pod B IP        │                           │
       │     (kube-proxy rules)      │                           │
       ▼                             │                           │
 [Routing Decision]                  │                           │
       │                             │                           │
       │ ip_forward=1                │                           │
       ▼                             │                           │
 [Forward to Node 2]─────────────────┴──────────────────────────▶
                                                                  │
                                                                  ▼
                                                            [Pod B receives]
```

### Step-by-Step Flow:

1. **Pod A sends packet to Service VIP** (10.96.0.10)
2. **Packet hits Linux bridge** on Node 1
3. **bridge-nf-call-iptables=1** → Bridge sends packet to iptables
4. **iptables processes packet** → kube-proxy rules apply DNAT to Pod B's IP
5. **ip_forward=1** → Kernel forwards packet to Node 2
6. **Packet arrives at Pod B** on Node 2

Without any of these parameters, this flow breaks at different stages.

---

## Configuration

### Loading Required Kernel Modules

Before setting these parameters, ensure the `br_netfilter` module is loaded:

```bash
# Load the module
sudo modprobe br_netfilter

# Verify it's loaded
lsmod | grep br_netfilter

# Load at boot (add to /etc/modules-load.d/)
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

### Setting the Parameters

Create a sysctl configuration file:

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```

Apply the settings:

```bash
sudo sysctl --system
```

### Verification

Check that all parameters are set correctly:

```bash
# Check individual parameters
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward

# Or check all at once
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
```

Expected output:
```
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
```

### Verification on CKA Cluster Nodes

```powershell
# Check on control plane
ssh k8s-control "sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward"

# Check on all nodes
foreach ($node in @("k8s-control", "k8s-worker1", "k8s-worker2")) {
    Write-Host "`n=== $node ===" -ForegroundColor Cyan
    ssh $node "sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward"
}
```

---

## Troubleshooting

### Issue: "cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables"

**Cause**: The `br_netfilter` kernel module is not loaded

**Solution**:
```bash
sudo modprobe br_netfilter
lsmod | grep br_netfilter
```

Make it persistent:
```bash
echo "br_netfilter" | sudo tee -a /etc/modules-load.d/k8s.conf
```

---

### Issue: Parameters reset after reboot

**Cause**: Settings not persisted in `/etc/sysctl.d/`

**Solution**: Ensure settings are in a file under `/etc/sysctl.d/` (e.g., `k8s.conf`)
```bash
ls -l /etc/sysctl.d/k8s.conf
cat /etc/sysctl.d/k8s.conf
```

---

### Issue: Pod-to-pod communication fails across nodes

**Symptoms**:
- Pods can communicate within same node
- Cross-node pod communication fails
- `ping` or `curl` between pods on different nodes times out

**Check**:
```bash
# Verify ip_forward is enabled
sysctl net.ipv4.ip_forward

# Check CNI plugin logs
kubectl logs -n kube-system -l k8s-app=cilium

# Verify routing
ip route show
```

---

### Issue: Services not working

**Symptoms**:
- Cannot reach Service ClusterIP
- Service endpoints exist but traffic doesn't reach pods
- `kubectl get endpoints` shows backends but connection fails

**Check**:
```bash
# Verify iptables bridging is enabled
sysctl net.bridge.bridge-nf-call-iptables

# Check kube-proxy iptables rules
sudo iptables -t nat -L -n -v | grep <service-ip>

# Check kube-proxy logs
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

---

## CKA Exam Tips

1. **These settings are prerequisites** - You may need to configure them as part of cluster setup tasks
2. **Know how to verify** - Be able to quickly check if parameters are set correctly
3. **Understand the impact** - Know what breaks when each parameter is missing
4. **Module loading** - Remember to load `br_netfilter` module first
5. **Persistence** - Always configure in `/etc/sysctl.d/` for boot persistence

### Common Exam Scenarios

**Scenario 1**: "Cluster nodes are configured, but pod networking doesn't work"
- Check these kernel parameters first

**Scenario 2**: "Service IPs are not reachable"
- Verify `bridge-nf-call-iptables` is enabled

**Scenario 3**: "Configure a new node to join the cluster"
- Set these parameters before running `kubeadm join`

---

## References

- [Official Kubernetes Prerequisites](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
- [Linux Kernel Documentation - IP Sysctl](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
- [Bridge Netfilter Documentation](https://www.kernel.org/doc/Documentation/networking/bridge.txt)

---

## Quick Reference

```bash
# Complete setup (run on all nodes)
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Verify
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
```
