# Kubernetes Certificates and Authentication

## Table of Contents
1. [Overview](#overview)
2. [Authentication in Kubernetes](#authentication-in-kubernetes)
3. [Certificate-Based Authentication](#certificate-based-authentication)
4. [Kubernetes Certificate Infrastructure](#kubernetes-certificate-infrastructure)
5. [Certificate Types](#certificate-types)
6. [Certificate SANs (Subject Alternative Names)](#certificate-sans-subject-alternative-names)
7. [Certificate Locations](#certificate-locations)
8. [Certificate Lifecycle Management](#certificate-lifecycle-management)
9. [Common Certificate Issues](#common-certificate-issues)
10. [Practical Examples](#practical-examples)
11. [CKA Exam Tips](#cka-exam-tips)

---

## Overview

Kubernetes uses a Public Key Infrastructure (PKI) to secure communication between cluster components and authenticate users. Understanding certificates is crucial for cluster administration, troubleshooting, and passing the CKA exam.

**Why Certificates Matter:**
- Secure communication between cluster components (API server, kubelet, etcd)
- User and service account authentication
- Mutual TLS (mTLS) for encrypted traffic
- Authorization and access control foundation

---

## Authentication in Kubernetes

Kubernetes supports multiple authentication methods:

### 1. X.509 Client Certificates (Most Common)
- Used by cluster components and administrators
- Based on PKI with Certificate Authority (CA)
- Strong security, widely supported

### 2. Service Account Tokens
- For pods authenticating to the API server
- JWT tokens signed by the cluster
- Automatically mounted into pods

### 3. Static Token Files
- Basic authentication (deprecated)
- Not recommended for production

### 4. Bootstrap Tokens
- Used during node joining (kubeadm)
- Time-limited, single-use tokens

### 5. OpenID Connect (OIDC)
- Integration with external identity providers
- Common in enterprise environments

### 6. Webhook Authentication
- Delegates authentication to external service

**For CKA:** Focus primarily on X.509 certificates and service account tokens.

---

## Certificate-Based Authentication

### How It Works

1. **Certificate Authority (CA)** creates and signs certificates
2. **Client** presents certificate to API server
3. **API server** validates certificate against CA
4. **Subject CN (Common Name)** becomes the username
5. **Subject O (Organization)** becomes the group membership

### Certificate Chain of Trust

```
Root CA Certificate (ca.crt)
    ├── API Server Certificate (apiserver.crt)
    ├── Kubelet Certificates (kubelet.crt)
    ├── Controller Manager Certificate (controller-manager.crt)
    ├── Scheduler Certificate (scheduler.crt)
    ├── Admin User Certificate (admin.crt)
    └── Service Account Key Pair (sa.key, sa.pub)
```

### Certificate Validation Process

```
┌─────────────┐                           ┌──────────────────┐
│   kubectl   │  1. Present Certificate   │   API Server     │
│  (Client)   │ ─────────────────────────>│                  │
└─────────────┘                           │  2. Verify:      │
                                          │  - CA Signature   │
                                          │  - Expiration     │
                                          │  - SANs           │
                                          │  - Revocation     │
                                          └──────────────────┘
                                                    │
                                          3. Extract Username/Groups
                                                    │
                                          4. Authorization (RBAC)
                                                    │
                                          5. Admission Control
                                                    │
                                          6. ✓ Request Processed
```

---

## Kubernetes Certificate Infrastructure

### Certificate Authority (CA)

The cluster CA is the root of trust for all cluster certificates.

**Location:** `/etc/kubernetes/pki/ca.crt` and `/etc/kubernetes/pki/ca.key`

**Functions:**
- Signs all cluster component certificates
- Signs user certificates for kubectl access
- Validates incoming certificate requests

### Multiple CAs in Kubernetes

A Kubernetes cluster typically uses multiple CAs:

1. **Kubernetes CA** - Main cluster CA (`/etc/kubernetes/pki/ca.crt`)
2. **Front Proxy CA** - For API aggregation (`/etc/kubernetes/pki/front-proxy-ca.crt`)
3. **Etcd CA** - Separate CA for etcd cluster (`/etc/kubernetes/pki/etcd/ca.crt`)

---

## Certificate Types

### 1. Server Certificates

Used by services to prove their identity to clients.

#### API Server Certificate

**File:** `/etc/kubernetes/pki/apiserver.crt`

**Purpose:** Proves API server identity to clients (kubectl, kubelet, etc.)

**Must Include SANs:**
- Cluster DNS names (kubernetes, kubernetes.default, kubernetes.default.svc, kubernetes.default.svc.cluster.local)
- Control plane IP addresses
- Control plane hostnames
- Load balancer addresses (if used)

**Example SANs in your setup:**
```yaml
apiServer:
  certSANs:
  - "k8s-control"          # Hostname
  - "192.168.56.10"        # IP address
  - "localhost"            # Local access
  - "127.0.0.1"           # Loopback
  - "kubernetes"           # Service name
  - "kubernetes.default"
```

#### Kubelet Server Certificate

**Location:** Configured via kubelet config (typically `/var/lib/kubelet/pki/`)

**Purpose:** Proves kubelet identity when API server connects for logs, exec, port-forward

### 2. Client Certificates

Used to authenticate to services.

#### API Server Client Certificates

**Admin Certificate:** `/etc/kubernetes/admin.conf` (embedded)
- **CN:** `kubernetes-admin`
- **O:** `system:masters`
- Provides cluster-admin privileges

**Controller Manager Certificate:**
- **CN:** `system:kube-controller-manager`
- Used by controller manager to authenticate to API server

**Scheduler Certificate:**
- **CN:** `system:kube-scheduler`
- Used by scheduler to authenticate to API server

#### Kubelet Client Certificate

**Purpose:** Kubelet authenticates to API server

**CN Format:** `system:node:<nodename>`
**O:** `system:nodes`

**Example:**
```
CN: system:node:k8s-worker1
O: system:nodes
```

This grants permissions via Node Authorization mode.

### 3. Peer Certificates

Used for mutual authentication between cluster members.

#### Etcd Certificates

**Peer Certificate:** `/etc/kubernetes/pki/etcd/peer.crt`
- For etcd member-to-member communication

**Server Certificate:** `/etc/kubernetes/pki/etcd/server.crt`
- For etcd client connections

---

## Certificate SANs (Subject Alternative Names)

### What are SANs?

SANs allow a certificate to be valid for multiple hostnames and IP addresses. Without proper SANs, you'll get certificate validation errors.

### Why SANs Matter

**Scenario:** You configure `controlPlaneEndpoint: "k8s-control:6443"` but later try to connect from Windows using IP `192.168.56.10`.

**Without SAN for 192.168.56.10:**
```
Unable to connect to the server: x509: certificate is valid for
k8s-control, kubernetes, kubernetes.default, not 192.168.56.10
```

**With SAN for 192.168.56.10:**
```
✓ Connection successful
```

### Configuring SANs in kubeadm

```yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
apiServer:
  certSANs:
  - "k8s-control"              # Primary hostname
  - "192.168.56.10"            # Control plane IP
  - "10.0.0.50"                # Load balancer IP (if applicable)
  - "control.example.com"      # External DNS (if applicable)
  - "localhost"
  - "127.0.0.1"
```

### Viewing Certificate SANs

```bash
# View API server certificate SANs
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 10 "Subject Alternative Name"
```

**Expected Output:**
```
X509v3 Subject Alternative Name:
    DNS:k8s-control, DNS:kubernetes, DNS:kubernetes.default,
    DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local,
    IP Address:192.168.56.10, IP Address:10.96.0.1
```

### Adding SANs After Cluster Creation

If you need to add SANs after initialization:

1. **Backup existing certificates:**
   ```bash
   sudo cp -r /etc/kubernetes/pki /etc/kubernetes/pki.backup
   ```

2. **Create kubeadm config with new SANs:**
   ```bash
   kubectl -n kube-system get configmap kubeadm-config -o yaml > kubeadm-config.yaml
   # Edit to add certSANs
   ```

3. **Regenerate API server certificate:**
   ```bash
   sudo kubeadm init phase certs apiserver --config kubeadm-config.yaml
   ```

4. **Restart API server:**
   ```bash
   sudo systemctl restart kubelet
   # Or move the API server manifest temporarily
   sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
   sleep 10
   sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
   ```

---

## Certificate Locations

### Control Plane Node

**Main PKI Directory:** `/etc/kubernetes/pki/`

```
/etc/kubernetes/pki/
├── ca.crt                          # Cluster CA certificate (public)
├── ca.key                          # Cluster CA private key
├── apiserver.crt                   # API server certificate
├── apiserver.key                   # API server private key
├── apiserver-kubelet-client.crt    # API server client cert for kubelet
├── apiserver-kubelet-client.key
├── front-proxy-ca.crt              # Front proxy CA
├── front-proxy-ca.key
├── front-proxy-client.crt
├── front-proxy-client.key
├── sa.key                          # Service account signing key
├── sa.pub                          # Service account public key
└── etcd/
    ├── ca.crt                      # Etcd CA certificate
    ├── ca.key                      # Etcd CA private key
    ├── server.crt                  # Etcd server certificate
    ├── server.key
    ├── peer.crt                    # Etcd peer certificate
    ├── peer.key
    ├── healthcheck-client.crt
    └── healthcheck-client.key
```

### Kubeconfig Files

Kubeconfig files embed certificates for authentication:

```
/etc/kubernetes/
├── admin.conf           # Admin user kubeconfig (system:masters)
├── controller-manager.conf
├── kubelet.conf
└── scheduler.conf
```

**Structure of a kubeconfig:**
```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: <base64-encoded-ca.crt>
    server: https://k8s-control:6443
  name: kubernetes
users:
- name: kubernetes-admin
  user:
    client-certificate-data: <base64-encoded-admin.crt>
    client-key-data: <base64-encoded-admin.key>
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
```

### Worker Nodes

**Kubelet PKI:** `/var/lib/kubelet/pki/`

```
/var/lib/kubelet/pki/
├── kubelet.crt          # Kubelet server certificate
├── kubelet.key
├── kubelet-client-current.pem  # Kubelet client certificate (auto-rotated)
└── kubelet-client-<timestamp>.pem
```

**Kubelet Config:** `/var/lib/kubelet/config.yaml`
**Kubelet Kubeconfig:** `/etc/kubernetes/kubelet.conf`

---

## Certificate Lifecycle Management

### Certificate Expiration

**Default Validity:**
- kubeadm certificates: **1 year**
- kubelet certificates (with rotation): **1 year**, auto-renewed

**Critical:** Expired certificates break cluster functionality!

### Checking Certificate Expiration

#### Using kubeadm
```bash
# Check all certificate expiration dates
sudo kubeadm certs check-expiration
```

**Example Output:**
```
CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Dec 15, 2025 10:30 UTC   364d            ca                      no
apiserver                  Dec 15, 2025 10:30 UTC   364d            ca                      no
apiserver-etcd-client      Dec 15, 2025 10:30 UTC   364d            etcd-ca                 no
apiserver-kubelet-client   Dec 15, 2025 10:30 UTC   364d            ca                      no
controller-manager.conf    Dec 15, 2025 10:30 UTC   364d            ca                      no
etcd-healthcheck-client    Dec 15, 2025 10:30 UTC   364d            etcd-ca                 no
etcd-peer                  Dec 15, 2025 10:30 UTC   364d            etcd-ca                 no
etcd-server                Dec 15, 2025 10:30 UTC   364d            etcd-ca                 no
front-proxy-client         Dec 15, 2025 10:30 UTC   364d            front-proxy-ca          no
scheduler.conf             Dec 15, 2025 10:30 UTC   364d            ca                      no
```

#### Using openssl
```bash
# Check API server certificate
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Validity"

# Check expiration date only
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate
```

### Renewing Certificates

#### Manual Renewal (All Certificates)
```bash
# Renew all certificates
sudo kubeadm certs renew all

# Restart control plane components
sudo systemctl restart kubelet
```

#### Renew Specific Certificate
```bash
# Renew only API server certificate
sudo kubeadm certs renew apiserver

# Renew admin.conf
sudo kubeadm certs renew admin.conf
```

#### After Renewal
```bash
# Update your kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Or on Windows host, copy again
scp k8s-control:~/.kube/config "$env:USERPROFILE\.kube\config"
```

### Automatic Certificate Rotation

#### Kubelet Certificate Rotation

Enable in kubelet configuration:

```yaml
# /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
rotateCertificates: true
serverTLSBootstrap: true  # For server certificate rotation
```

**How it works:**
1. Kubelet monitors certificate expiration
2. Requests new certificate before expiration (at 70-80% of lifetime)
3. Certificate Signing Request (CSR) created
4. Controller manager approves and signs CSR (if auto-approval enabled)
5. New certificate issued and used

**View pending CSRs:**
```bash
kubectl get csr
```

**Manually approve CSR:**
```bash
kubectl certificate approve <csr-name>
```

---

## Common Certificate Issues

### 1. Certificate Expired

**Symptoms:**
```
Unable to connect to the server: x509: certificate has expired or is not yet valid
```

**Solution:**
```bash
# On control plane node
sudo kubeadm certs check-expiration
sudo kubeadm certs renew all
sudo systemctl restart kubelet

# Update kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
```

### 2. Invalid Certificate SANs

**Symptoms:**
```
x509: certificate is valid for k8s-control, kubernetes, not 192.168.56.10
```

**Solution:**
Add missing SANs to kubeadm config and regenerate API server certificate:
```bash
sudo kubeadm init phase certs apiserver --config kubeadm-config.yaml
```

### 3. CA Certificate Mismatch

**Symptoms:**
```
x509: certificate signed by unknown authority
```

**Causes:**
- Wrong CA certificate in kubeconfig
- CA certificate was regenerated
- Kubeconfig from different cluster

**Solution:**
```bash
# Verify CA certificate
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /tmp/ca.crt
openssl x509 -in /tmp/ca.crt -text -noout

# Compare with cluster CA
sudo openssl x509 -in /etc/kubernetes/pki/ca.crt -text -noout

# If different, update kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
```

### 4. Kubelet Not Joining Cluster

**Symptoms:**
```
kubelet.go: Failed to start ContainerManager failed to get rootfs info:
unable to authenticate the request due to an error: x509: certificate signed by unknown authority
```

**Solution:**
```bash
# On worker node, check kubelet config
sudo cat /var/lib/kubelet/config.yaml | grep -i cert

# Verify CA certificate
sudo cat /etc/kubernetes/kubelet.conf

# If invalid, rejoin the node
sudo kubeadm reset
# On control plane: kubeadm token create --print-join-command
sudo kubeadm join ...
```

### 5. Service Account Token Issues

**Symptoms:**
```
Pods can't authenticate to API server
Unable to authenticate the request
```

**Solution:**
```bash
# Check service account key pair exists
sudo ls -la /etc/kubernetes/pki/sa.{key,pub}

# Verify API server is using correct key
ps aux | grep kube-apiserver | grep service-account-key

# If missing, regenerate
sudo kubeadm init phase certs sa
sudo systemctl restart kubelet
```

---

## Practical Examples

### Example 1: Creating a User Certificate

**Scenario:** Create a certificate for user "john" in group "developers"

```bash
# 1. Generate private key
openssl genrsa -out john.key 2048

# 2. Create Certificate Signing Request (CSR)
openssl req -new -key john.key -out john.csr -subj "/CN=john/O=developers"

# 3. Sign with cluster CA
sudo openssl x509 -req -in john.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial \
  -out john.crt \
  -days 365

# 4. Create kubeconfig for john
kubectl config set-credentials john \
  --client-certificate=john.crt \
  --client-key=john.key \
  --embed-certs=true

kubectl config set-context john-context \
  --cluster=kubernetes \
  --user=john

# 5. Create RBAC role and binding
kubectl create role developer --verb=get,list,watch --resource=pods
kubectl create rolebinding john-developer --role=developer --user=john

# 6. Test
kubectl --context=john-context get pods
```

### Example 2: Using Kubernetes CSR API

**Better approach for user certificate creation:**

```bash
# 1. Generate key
openssl genrsa -out john.key 2048

# 2. Create CSR
openssl req -new -key john.key -out john.csr -subj "/CN=john/O=developers"

# 3. Create Kubernetes CSR object
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john-csr
spec:
  request: $(cat john.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

# 4. Approve CSR
kubectl certificate approve john-csr

# 5. Get certificate
kubectl get csr john-csr -o jsonpath='{.status.certificate}' | base64 -d > john.crt

# 6. Create kubeconfig
kubectl config set-credentials john \
  --client-certificate=john.crt \
  --client-key=john.key \
  --embed-certs=true
```

### Example 3: Extracting Certificates from Kubeconfig

```bash
# Extract client certificate
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > client.crt

# Extract client key
kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > client.key

# Extract CA certificate
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt

# Use with curl to access API server
curl --cert client.crt --key client.key --cacert ca.crt https://k8s-control:6443/api/v1/namespaces
```

### Example 4: Debugging Certificate Issues

```bash
# Check certificate details
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# Verify certificate matches key
openssl x509 -noout -modulus -in /etc/kubernetes/pki/apiserver.crt | openssl md5
openssl rsa -noout -modulus -in /etc/kubernetes/pki/apiserver.key | openssl md5
# MD5 hashes should match

# Verify certificate chain
openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt

# Check certificate is not expired
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -checkend 0
echo $?  # 0 = valid, 1 = expired

# Test API server certificate with openssl
openssl s_client -connect k8s-control:6443 -servername k8s-control < /dev/null
```

---

## CKA Exam Tips

### What You Need to Know

1. **Certificate locations** - Where to find certificates on control plane and worker nodes
2. **Certificate expiration** - How to check and renew certificates
3. **Certificate SANs** - Understanding why SANs matter for API server access
4. **Kubeconfig structure** - How certificates are embedded in kubeconfig files
5. **Creating user certificates** - Using CSR API or manual signing
6. **Troubleshooting** - Diagnosing and fixing certificate issues

### Common Exam Tasks

#### Task 1: Check Certificate Expiration
```bash
sudo kubeadm certs check-expiration
```

#### Task 2: Renew Certificates
```bash
sudo kubeadm certs renew all
sudo systemctl restart kubelet
```

#### Task 3: Create User with Certificate
```bash
# Use CSR API approach (shown in Example 2)
openssl genrsa -out user.key 2048
openssl req -new -key user.key -out user.csr -subj "/CN=user/O=group"
# Create CSR object, approve, extract certificate
```

#### Task 4: Configure Kubeconfig
```bash
kubectl config set-credentials user --client-certificate=user.crt --client-key=user.key
kubectl config set-context user-context --cluster=kubernetes --user=user
kubectl config use-context user-context
```

#### Task 5: Fix Certificate Issue
```bash
# Check expiration
sudo kubeadm certs check-expiration

# Check SANs
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 10 "Subject Alternative Name"

# Verify certificate chain
openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt
```

### Exam Time-Saving Commands

```bash
# Quickly check all certificates
sudo kubeadm certs check-expiration

# View certificate details
openssl x509 -in <cert> -text -noout | grep -E "(Subject:|Issuer:|Not Before|Not After|DNS:|IP Address:)"

# Renew all at once
sudo kubeadm certs renew all && sudo systemctl restart kubelet

# Extract from kubeconfig
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d | openssl x509 -text -noout

# Approve all pending CSRs (if appropriate)
kubectl get csr -o name | xargs kubectl certificate approve
```

### Important Notes for Exam

- **Kubeadm is your friend:** Most certificate operations can be done with `kubeadm certs` subcommands
- **Don't delete the CA:** Never delete `/etc/kubernetes/pki/ca.key` unless regenerating the entire cluster
- **Check before you act:** Always check certificate expiration before renewing
- **Document flags:** The exam allows Kubernetes documentation, know where to find certificate configuration options
- **Time management:** Certificate tasks are usually quick, don't overthink them

---

## Summary

**Key Takeaways:**

1. Kubernetes uses X.509 certificates for secure authentication and communication
2. The cluster CA is the root of trust for all cluster certificates
3. Certificate SANs are critical for multi-access scenarios (hostname, IP, DNS)
4. Certificates expire (default 1 year with kubeadm) and must be renewed
5. Use `kubeadm certs` commands for certificate management
6. Understand certificate locations for troubleshooting
7. Practice creating user certificates with CSR API
8. Know how to extract and view certificate details with openssl

**For CKA Success:**
- Practice certificate troubleshooting scenarios
- Know the certificate renewal workflow
- Understand kubeconfig structure and certificate embedding
- Be comfortable with openssl commands for certificate inspection
- Remember: `kubeadm certs check-expiration` is your first debugging step

---

## References

- [Kubernetes PKI Certificates](https://kubernetes.io/docs/setup/best-practices/certificates/)
- [kubeadm Certificate Management](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [Certificate Signing Requests](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/)
- [Authenticating](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)

---

**Document Version:** 1.0
**Last Updated:** 2025-01-01
**For:** CKA Training Environment
