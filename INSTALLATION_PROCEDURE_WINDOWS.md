# Kubernetes Cluster Installation Procedure (Windows)
## CKA Training Environment Setup for Windows

### Prerequisites
- Windows 10/11 Pro or Enterprise
- VirtualBox installed (download from https://www.virtualbox.org/)
- Minimum 8GB RAM available
- 50GB free disk space
- Ubuntu Server 24.04.3 LTS ISO downloaded (ubuntu-24.04.3-live-server-amd64.iso)
- PowerShell 5.1 or later (Run as Administrator)

### System Requirements Per Node
- **Control Plane**: 2 vCPUs, 2GB RAM, 20GB disk
- **Worker Nodes**: 2 vCPUs, 2GB RAM, 20GB disk each

### Important Windows Notes
- Run PowerShell as Administrator for VBoxManage commands
- VBoxManage is typically located at: `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe`
- Add VirtualBox to PATH or use full path in commands

---

## Setup: Add VirtualBox to PATH (PowerShell as Administrator)

```powershell
# Add VirtualBox to PATH for current session
$env:Path += ";C:\Program Files\Oracle\VirtualBox"

# Add VirtualBox to PATH permanently
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Oracle\VirtualBox", [EnvironmentVariableTarget]::Machine)

# Verify VBoxManage is accessible
VBoxManage --version
```

---

## Phase 1: VM Provisioning with VirtualBox CLI

**Quick Start**: Use the provided `provision-vms.ps1` script to automate all VM provisioning steps:
```powershell
powershell -ExecutionPolicy Bypass -File provision-vms.ps1
```

Or follow the manual steps below:

### Step 1: Set Variables (PowerShell)

```powershell
# Set VM storage location
$VMPath = "$env:USERPROFILE\VirtualBox VMs"

# Set ISO path (update with your actual path)
$ISOPath = "C:\Users\$env:USERNAME\Downloads\ubuntu-24.04.3-live-server-amd64.iso"

# Verify ISO exists
if (Test-Path $ISOPath) {
    Write-Host "ISO found at: $ISOPath" -ForegroundColor Green
} else {
    Write-Host "ISO not found! Please update `$ISOPath variable" -ForegroundColor Red
}
```

### Step 2: Create Host-Only Network (if not exists)

**Note**: This step is usually not needed as VirtualBox creates a host-only network by default. The provisioning script will configure DHCP with IP reservations automatically.

```powershell
# List existing host-only networks
VBoxManage list hostonlyifs

# Create host-only network (only if none exists)
VBoxManage hostonlyif create

# Configure host-only network (usually VirtualBox Host-Only Ethernet Adapter)
VBoxManage hostonlyif ipconfig "VirtualBox Host-Only Ethernet Adapter" --ip 192.168.56.1 --netmask 255.255.255.0
```

### Step 3: Create Control Plane Node

```powershell
# Create VM
VBoxManage createvm --name k8s-control --ostype Ubuntu_64 --register --basefolder "$VMPath"

# Configure VM resources
VBoxManage modifyvm k8s-control `
  --memory 2048 `
  --cpus 2 `
  --nic1 nat `
  --nic2 hostonly `
  --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" `
  --macaddress2 080027000010

# Create virtual hard disk
VBoxManage createhd --filename "$VMPath\k8s-control\k8s-control.vdi" --size 20480

# Attach storage controller
VBoxManage storagectl k8s-control --name "SATA Controller" --add sata --controller IntelAhci

# Attach hard disk
VBoxManage storageattach k8s-control `
  --storagectl "SATA Controller" `
  --port 0 `
  --device 0 `
  --type hdd `
  --medium "$VMPath\k8s-control\k8s-control.vdi"

# Attach Ubuntu ISO
VBoxManage storageattach k8s-control `
  --storagectl "SATA Controller" `
  --port 1 `
  --device 0 `
  --type dvddrive `
  --medium "$ISOPath"

# Enable boot from disk
VBoxManage modifyvm k8s-control --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Enable nested virtualization (if needed)
VBoxManage modifyvm k8s-control --nested-hw-virt on

# Create shared folder (maps host directory to VM)
# Uses current project directory as shared folder
$SharedPath = $PWD.Path
Write-Host "Using shared directory: $SharedPath" -ForegroundColor Green

VBoxManage sharedfolder add k8s-control `
  --name "k8s-shared" `
  --hostpath "$SharedPath" `
  --automount `
  --auto-mount-point /mnt/shared
```

### Step 4: Create Worker Node 1

```powershell
# Create VM
VBoxManage createvm --name k8s-worker1 --ostype Ubuntu_64 --register --basefolder "$VMPath"

# Configure VM resources
VBoxManage modifyvm k8s-worker1 `
  --memory 2048 `
  --cpus 2 `
  --nic1 nat `
  --nic2 hostonly `
  --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" `
  --macaddress2 080027000011

# Create virtual hard disk
VBoxManage createhd --filename "$VMPath\k8s-worker1\k8s-worker1.vdi" --size 20480

# Attach storage controller
VBoxManage storagectl k8s-worker1 --name "SATA Controller" --add sata --controller IntelAhci

# Attach hard disk
VBoxManage storageattach k8s-worker1 `
  --storagectl "SATA Controller" `
  --port 0 `
  --device 0 `
  --type hdd `
  --medium "$VMPath\k8s-worker1\k8s-worker1.vdi"

# Attach Ubuntu ISO
VBoxManage storageattach k8s-worker1 `
  --storagectl "SATA Controller" `
  --port 1 `
  --device 0 `
  --type dvddrive `
  --medium "$ISOPath"

# Enable boot from disk
VBoxManage modifyvm k8s-worker1 --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Enable nested virtualization (if needed)
VBoxManage modifyvm k8s-worker1 --nested-hw-virt on

# Create shared folder
VBoxManage sharedfolder add k8s-worker1 `
  --name "k8s-shared" `
  --hostpath "$SharedPath" `
  --automount `
  --auto-mount-point /mnt/shared
```

### Step 5: Create Worker Node 2

```powershell
# Create VM
VBoxManage createvm --name k8s-worker2 --ostype Ubuntu_64 --register --basefolder "$VMPath"

# Configure VM resources
VBoxManage modifyvm k8s-worker2 `
  --memory 2048 `
  --cpus 2 `
  --nic1 nat `
  --nic2 hostonly `
  --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" `
  --macaddress2 080027000012

# Create virtual hard disk
VBoxManage createhd --filename "$VMPath\k8s-worker2\k8s-worker2.vdi" --size 20480

# Attach storage controller
VBoxManage storagectl k8s-worker2 --name "SATA Controller" --add sata --controller IntelAhci

# Attach hard disk
VBoxManage storageattach k8s-worker2 `
  --storagectl "SATA Controller" `
  --port 0 `
  --device 0 `
  --type hdd `
  --medium "$VMPath\k8s-worker2\k8s-worker2.vdi"

# Attach Ubuntu ISO
VBoxManage storageattach k8s-worker2 `
  --storagectl "SATA Controller" `
  --port 1 `
  --device 0 `
  --type dvddrive `
  --medium "$ISOPath"

# Enable boot from disk
VBoxManage modifyvm k8s-worker2 --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Enable nested virtualization (if needed)
VBoxManage modifyvm k8s-worker2 --nested-hw-virt on

# Create shared folder
VBoxManage sharedfolder add k8s-worker2 `
  --name "k8s-shared" `
  --hostpath "$SharedPath" `
  --automount `
  --auto-mount-point /mnt/shared
```

### Step 6: Configure DHCP Reservations

```powershell
# Remove existing DHCP server if it exists
VBoxManage dhcpserver remove --network="HostInterfaceNetworking-VirtualBox Host-Only Ethernet Adapter" 2>$null

# Add DHCP server with reservations
VBoxManage dhcpserver add `
  --network="HostInterfaceNetworking-VirtualBox Host-Only Ethernet Adapter" `
  --server-ip=192.168.56.1 `
  --netmask=255.255.255.0 `
  --lower-ip=192.168.56.100 `
  --upper-ip=192.168.56.200 `
  --enable

# Add MAC-to-IP reservations for each node
VBoxManage dhcpserver modify `
  --network="HostInterfaceNetworking-VirtualBox Host-Only Ethernet Adapter" `
  --mac-address=08:00:27:00:00:10 `
  --fixed-address=192.168.56.10

VBoxManage dhcpserver modify `
  --network="HostInterfaceNetworking-VirtualBox Host-Only Ethernet Adapter" `
  --mac-address=08:00:27:00:00:11 `
  --fixed-address=192.168.56.11

VBoxManage dhcpserver modify `
  --network="HostInterfaceNetworking-VirtualBox Host-Only Ethernet Adapter" `
  --mac-address=08:00:27:00:00:12 `
  --fixed-address=192.168.56.12
```

**DHCP Reservations Summary:**
- k8s-control (MAC: 08:00:27:00:00:10) → 192.168.56.10
- k8s-worker1 (MAC: 08:00:27:00:00:11) → 192.168.56.11
- k8s-worker2 (MAC: 08:00:27:00:00:12) → 192.168.56.12

### Step 7: Start VMs and Install Ubuntu

```powershell
# Start VMs in headless mode
VBoxManage startvm k8s-control --type headless
VBoxManage startvm k8s-worker1 --type headless
VBoxManage startvm k8s-worker2 --type headless

# Alternative: Start with GUI for installation
# VBoxManage startvm k8s-control --type gui
```

**Manual Installation Steps:**

Complete the following steps on **EACH VM** (k8s-control, k8s-worker1, k8s-worker2):

1. **Start Ubuntu Server 24.04.3 LTS installation**
   - Select language and keyboard layout

2. **Set hostname** (important - must match):
   - Control plane: `k8s-control`
   - Worker 1: `k8s-worker1`
   - Worker 2: `k8s-worker2`

3. **Network configuration**:
   - **Use DHCP (default)** - Do NOT configure static IPs
   - The VMs will automatically receive their reserved IPs:
     - k8s-control: 192.168.56.10
     - k8s-worker1: 192.168.56.11
     - k8s-worker2: 192.168.56.12

4. **Create user account**:
   - Username: `k8s`
   - Password: `k8s`
   - Server name: (use hostname from step 2)

5. **⚠️ CRITICAL: Enable OpenSSH Server**
   - When you reach the "Featured Server Snaps" screen
   - **YOU MUST check [X] OpenSSH server**
   - Without this, SSH configuration in Phase 2 will fail!
   - If you forget this step, you'll need to install SSH manually later

6. **Complete installation**
   - Wait for installation to finish
   - Remove installation media when prompted
   - Reboot

**After Installation:**
- Login with username `k8s` and password `k8s`
- Verify SSH is running: `sudo systemctl status ssh`
- Check IP address: `ip a` (should show 192.168.56.10/11/12)

---

## Phase 2: SSH Installation on Nodes (if needed)

**Skip this phase if you enabled OpenSSH server during Ubuntu installation.**

If you forgot to enable OpenSSH during installation, you need to install it manually on each VM before proceeding with SSH configuration.

### Verify SSH Status

Login to each VM via the VirtualBox console and check if SSH is running:

```bash
# Check SSH service status
sudo systemctl status ssh
```

If you see "Unit ssh.service could not be found", SSH is not installed.

### Install OpenSSH Server

Run the following commands on **EACH VM** (k8s-control, k8s-worker1, k8s-worker2):

```bash
# Update package list
sudo apt update

# Install OpenSSH server
sudo apt install -y openssh-server

# Enable SSH to start on boot
sudo systemctl enable ssh

# Start SSH service
sudo systemctl start ssh

# Verify SSH is running
sudo systemctl status ssh
```

### Verify Installation

After installing SSH on all nodes, verify connectivity from Windows:

```powershell
# Test SSH connectivity (from Windows PowerShell)
ssh k8s@192.168.56.10 "echo 'k8s-control SSH OK'"
ssh k8s@192.168.56.11 "echo 'k8s-worker1 SSH OK'"
ssh k8s@192.168.56.12 "echo 'k8s-worker2 SSH OK'"
```

You should be prompted for the password (`k8s`) for each node.

---

## Phase 3: SSH Configuration (Windows)

**Prerequisites**: Ensure all VMs have completed Ubuntu installation and OpenSSH server is running on each node.

### Step 1: Verify OpenSSH Client on Windows

```powershell
# Check if OpenSSH Client is installed
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'

# Install OpenSSH Client if needed
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Verify SSH is available
ssh -V
```

**Note**: SSH keys are already included in the project repository (`.ssh/k8s_cluster_key` and `.ssh/k8s_cluster_key.pub`). This is a local training environment, so keys are committed to git for convenience.

### Step 2: Test SSH Connectivity (Optional but Recommended)

Before copying SSH keys, verify that SSH server is running on each VM:

```powershell
# Test SSH connectivity to each node (you'll be prompted for password: k8s)
ssh k8s@192.168.56.10 "echo 'k8s-control SSH OK' && exit"
ssh k8s@192.168.56.11 "echo 'k8s-worker1 SSH OK' && exit"
ssh k8s@192.168.56.12 "echo 'k8s-worker2 SSH OK' && exit"
```

**If SSH connection fails:**
- Verify the VM is running and Ubuntu installation is complete
- Check SSH is running on the VM: Login via VirtualBox console and run `sudo systemctl status ssh`
- If SSH is not installed, see Phase 2: SSH Installation on Nodes
- Verify IP addresses match: Run `ip a` on each VM

### Step 3: Copy SSH Keys to All Nodes

```powershell
# Define variables
$K8S_USER = "k8s"
$SSH_KEY_PATH = "$PWD\.ssh\k8s_cluster_key"

# Copy SSH key to control plane
Get-Content "$SSH_KEY_PATH.pub" | ssh "$K8S_USER@192.168.56.10" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Copy SSH key to worker1
Get-Content "$SSH_KEY_PATH.pub" | ssh "$K8S_USER@192.168.56.11" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Copy SSH key to worker2
Get-Content "$SSH_KEY_PATH.pub" | ssh "$K8S_USER@192.168.56.12" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### Step 4: Configure SSH Config File

```powershell
# Create or update SSH config in user's .ssh directory
$sshConfigDir = "$env:USERPROFILE\.ssh"
New-Item -ItemType Directory -Force -Path $sshConfigDir | Out-Null

# Get absolute path to project SSH key
$SSH_KEY_PATH = "$PWD\.ssh\k8s_cluster_key"

# Create SSH config file
$sshConfig = @"

# Kubernetes Cluster Nodes
Host k8s-control
    HostName 192.168.56.10
    User k8s
    IdentityFile $SSH_KEY_PATH
    StrictHostKeyChecking accept-new

Host k8s-worker1
    HostName 192.168.56.11
    User k8s
    IdentityFile $SSH_KEY_PATH
    StrictHostKeyChecking accept-new

Host k8s-worker2
    HostName 192.168.56.12
    User k8s
    IdentityFile $SSH_KEY_PATH
    StrictHostKeyChecking accept-new
"@

# Add to SSH config
Add-Content -Path "$sshConfigDir\config" -Value $sshConfig

Write-Host "SSH config updated with project SSH key path" -ForegroundColor Green
```

**Note about StrictHostKeyChecking:**
- `accept-new` will automatically accept and save host keys on first connection
- You'll see a "Warning: Permanently added..." message ONCE per host
- Subsequent connections will be silent (no warnings)
- This is the recommended setting for known, trusted hosts

### Step 5: Test SSH Access

```powershell
# Test connection to control plane
ssh k8s-control "hostname && ip a"

# Test connection to worker1
ssh k8s-worker1 "hostname && ip a"

# Test connection to worker2
ssh k8s-worker2 "hostname && ip a"
```

### Step 6: Configure Passwordless Sudo on All Nodes

```powershell
# Configure passwordless sudo on all nodes
$K8S_USER = "k8s"
$K8S_PASSWORD = "k8s"

# k8s-control
ssh k8s-control "echo '$K8S_PASSWORD' | sudo -S sh -c 'echo \`"$K8S_USER ALL=`(ALL`) NOPASSWD:ALL\`" | tee /etc/sudoers.d/$K8S_USER > /dev/null && chmod 0440 /etc/sudoers.d/$K8S_USER'"

# k8s-worker1
ssh k8s-worker1 "echo '$K8S_PASSWORD' | sudo -S sh -c 'echo \`"$K8S_USER ALL=`(ALL`) NOPASSWD:ALL\`" | tee /etc/sudoers.d/$K8S_USER > /dev/null && chmod 0440 /etc/sudoers.d/$K8S_USER'"

# k8s-worker2
ssh k8s-worker2 "echo '$K8S_PASSWORD' | sudo -S sh -c 'echo \`"$K8S_USER ALL=`(ALL`) NOPASSWD:ALL\`" | tee /etc/sudoers.d/$K8S_USER > /dev/null && chmod 0440 /etc/sudoers.d/$K8S_USER'"

# Test passwordless sudo (should work without password now)
ssh k8s-control "sudo whoami"  # Should output: root
ssh k8s-worker1 "sudo whoami"  # Should output: root
ssh k8s-worker2 "sudo whoami"  # Should output: root
```

**Note:** The backticks (`` ` ``) escape special characters in PowerShell. The `-S` flag tells sudo to read the password from stdin. We use `tee` to write to the protected directory with sudo privileges.

### Step 7: Configure /etc/hosts on All Nodes

```powershell
# Create hosts entries script
$hostsEntries = @"
192.168.56.10   k8s-control
192.168.56.11   k8s-worker1
192.168.56.12   k8s-worker2
"@

# Add to /etc/hosts on all nodes
ssh k8s-control "echo '$hostsEntries' | sudo tee -a /etc/hosts"
ssh k8s-worker1 "echo '$hostsEntries' | sudo tee -a /etc/hosts"
ssh k8s-worker2 "echo '$hostsEntries' | sudo tee -a /etc/hosts"
```

### Step 8: Add Windows Hosts File Entries (Optional)

```powershell
# Run as Administrator
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = @"

# Kubernetes Cluster Nodes
192.168.56.10   k8s-control
192.168.56.11   k8s-worker1
192.168.56.12   k8s-worker2
"@

Add-Content -Path $hostsPath -Value $hostsContent

# Verify
Get-Content $hostsPath | Select-String "k8s"
```

---

## Phase 4: Shared Folder Configuration

### Step 1: Install VirtualBox Guest Additions on All Nodes

VirtualBox Guest Additions are required for shared folder functionality.

```powershell
# Define nodes
$nodes = @("k8s-control", "k8s-worker1", "k8s-worker2")

# Install required packages on all nodes
foreach ($node in $nodes) {
    Write-Host "Installing Guest Additions prerequisites on $node..." -ForegroundColor Green
    ssh $node "sudo apt update && sudo apt install -y build-essential dkms linux-headers-`$(uname -r)"
}
```

### Step 2: Insert Guest Additions CD and Install

```powershell
# Find VBoxGuestAdditions.iso path
$VBoxPath = "C:\Program Files\Oracle\VirtualBox"
$GuestAdditionsISO = "$VBoxPath\VBoxGuestAdditions.iso"

if (-not (Test-Path $GuestAdditionsISO)) {
    Write-Host "Guest Additions ISO not found at: $GuestAdditionsISO" -ForegroundColor Red
    Write-Host "Please verify VirtualBox installation path" -ForegroundColor Yellow
    exit
}

# Insert Guest Additions CD to each VM
VBoxManage storageattach k8s-control `
  --storagectl "SATA Controller" `
  --port 1 `
  --device 0 `
  --type dvddrive `
  --medium "$GuestAdditionsISO"

VBoxManage storageattach k8s-worker1 `
  --storagectl "SATA Controller" `
  --port 1 `
  --device 0 `
  --type dvddrive `
  --medium "$GuestAdditionsISO"

VBoxManage storageattach k8s-worker2 `
  --storagectl "SATA Controller" `
  --port 1 `
  --device 0 `
  --type dvddrive `
  --medium "$GuestAdditionsISO"

# Install Guest Additions on each node
$installScript = @'
sudo mkdir -p /mnt/cdrom
sudo mount /dev/sr0 /mnt/cdrom
sudo /mnt/cdrom/VBoxLinuxAdditions.run || true
sudo umount /mnt/cdrom
'@

foreach ($node in $nodes) {
    Write-Host "Installing Guest Additions on $node..." -ForegroundColor Green
    ssh $node $installScript
}

# Reboot all nodes
foreach ($node in $nodes) {
    Write-Host "Rebooting $node..." -ForegroundColor Yellow
    ssh $node "sudo reboot"
}

# Wait for nodes to come back online
Write-Host "Waiting for nodes to reboot (60 seconds)..." -ForegroundColor Cyan
Start-Sleep -Seconds 60
```

### Step 3: Configure Shared Folder Permissions

```powershell
# Add user to vboxsf group on each node
foreach ($node in $nodes) {
    Write-Host "Configuring shared folder on $node..." -ForegroundColor Green
    ssh $node "sudo usermod -aG vboxsf `$USER"
}

# Create mount point if needed
foreach ($node in $nodes) {
    ssh $node "sudo mkdir -p /mnt/shared && sudo chown `$USER:`$USER /mnt/shared"
}
```

### Step 4: Verify Shared Folder Access

```powershell
# Create test file from Windows host
$SharedPath = $PWD.Path
"Test file from Windows host - $(Get-Date)" | Out-File -FilePath "$SharedPath\test.txt" -Encoding UTF8

# Test access from all nodes
foreach ($node in $nodes) {
    Write-Host "`nTesting shared folder on $node..." -ForegroundColor Cyan
    ssh $node "ls -la /mnt/shared/ && cat /mnt/shared/test.txt"
}

# Create test file from VM
ssh k8s-control "echo 'Test from control plane' > /mnt/shared/from-vm.txt"

# Verify on Windows host
Write-Host "`nVerifying file from VM on Windows host:" -ForegroundColor Cyan
Get-Content "$SharedPath\from-vm.txt"
```

### Step 5: Set Up Auto-Mount (if needed)

```powershell
# Add to /etc/fstab if shared folder doesn't auto-mount
foreach ($node in $nodes) {
    ssh $node "echo 'k8s-shared    /mnt/shared    vboxsf    defaults,uid=1000,gid=1000    0    0' | sudo tee -a /etc/fstab"
}
```

### Shared Folder Usage Examples

```powershell
# Copy Kubernetes manifests from Windows to VMs
Copy-Item -Path ".\my-deployment.yaml" -Destination ".\"
ssh k8s-control "kubectl apply -f /mnt/shared/my-deployment.yaml"

# Copy logs from VMs to Windows
ssh k8s-control "sudo journalctl -u kubelet --no-pager > /mnt/shared/kubelet.log"
Get-Content ".\kubelet.log"

# Share configuration files
Copy-Item -Path "$env:USERPROFILE\.kube\config" -Destination ".\kubeconfig"
ssh k8s-worker1 "cat /mnt/shared/kubeconfig"

# Transfer files between host and cluster
# From Windows to cluster:
Copy-Item -Path ".\local-file.txt" -Destination ".\"

# From cluster to Windows:
ssh k8s-control "cp /var/log/syslog /mnt/shared/syslog.txt"
```

### Create PowerShell Helper Function for Shared Folder

```powershell
# Add to PowerShell profile
function Copy-ToK8sCluster {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        [string]$DestinationName
    )

    $SharedPath = $PWD.Path
    
    if ([string]::IsNullOrEmpty($DestinationName)) {
        $DestinationName = Split-Path $SourcePath -Leaf
    }
    
    Copy-Item -Path $SourcePath -Destination "$SharedPath\$DestinationName"
    Write-Host "Copied to shared folder. Access from VMs at: /mnt/shared/$DestinationName" -ForegroundColor Green
}

function Copy-FromK8sCluster {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileName,
        [string]$DestinationPath = "."
    )

    $SharedPath = $PWD.Path
    $SourceFile = "$SharedPath\$FileName"
    
    if (Test-Path $SourceFile) {
        Copy-Item -Path $SourceFile -Destination $DestinationPath
        Write-Host "Copied from shared folder to: $DestinationPath" -ForegroundColor Green
    } else {
        Write-Host "File not found in shared folder: $FileName" -ForegroundColor Red
    }
}

# Usage:
# Copy-ToK8sCluster -SourcePath ".\deployment.yaml"
# Copy-FromK8sCluster -FileName "kubelet.log" -DestinationPath ".\logs\"
```

---

## Phase 5: OS Configuration (Run on ALL Nodes via SSH)

### Step 1: Update System on All Nodes

```powershell
# Update all nodes
$nodes = @("k8s-control", "k8s-worker1", "k8s-worker2")
foreach ($node in $nodes) {
    Write-Host "Updating $node..." -ForegroundColor Green
    ssh $node "sudo apt update && sudo apt upgrade -y"
}
```

### Step 2: Disable Swap on All Nodes

```powershell
foreach ($node in $nodes) {
    Write-Host "Disabling swap on $node..." -ForegroundColor Green
    ssh $node "sudo swapoff -a && sudo sed -i '/ swap / s/^\(.*\)$/# \1/g' /etc/fstab"
}
```

### Step 3: Load Kernel Modules on All Nodes

```powershell
$kernelModules = @"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
"@

foreach ($node in $nodes) {
    Write-Host "Loading kernel modules on $node..." -ForegroundColor Green
    ssh $node $kernelModules
}
```

### Step 4: Configure Kernel Parameters on All Nodes

```powershell
$kernelParams = @"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
"@

foreach ($node in $nodes) {
    Write-Host "Configuring kernel parameters on $node..." -ForegroundColor Green
    ssh $node $kernelParams
}
```

### Step 5: Install Container Runtime (containerd) on All Nodes

```powershell
$installContainerd = @"
# Install dependencies
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install containerd
sudo apt update
sudo apt install -y containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
"@

foreach ($node in $nodes) {
    Write-Host "Installing containerd on $node..." -ForegroundColor Green
    ssh $node $installContainerd
}
```

### Step 6: Install Kubernetes Components on All Nodes

```powershell
$installK8s = @"
# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubelet, kubeadm, kubectl
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Hold packages at current version
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
sudo systemctl enable kubelet
"@

foreach ($node in $nodes) {
    Write-Host "Installing Kubernetes components on $node..." -ForegroundColor Green
    ssh $node $installK8s
}
```

---

## Phase 6: Initialize Kubernetes Cluster

### Step 1: Initialize Control Plane

```powershell
Write-Host "Initializing Kubernetes control plane..." -ForegroundColor Green

$initCommand = @"
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.56.10 \
  --control-plane-endpoint=192.168.56.10
"@

# Initialize and capture output
ssh k8s-control $initCommand | Tee-Object -FilePath "$env:USERPROFILE\k8s-init-output.txt"

Write-Host "`nInitialization output saved to: $env:USERPROFILE\k8s-init-output.txt" -ForegroundColor Yellow
Write-Host "IMPORTANT: Save the kubeadm join command from the output!" -ForegroundColor Red
```

### Step 2: Configure kubectl on Control Plane

```powershell
$configKubectl = @"
mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config
"@

ssh k8s-control $configKubectl

# Verify
ssh k8s-control "kubectl get nodes"
```

### Step 3: Install Pod Network Add-on (Cilium)

```powershell
Write-Host "Installing Cilium CNI..." -ForegroundColor Green

# Install Cilium CLI on control plane
ssh k8s-control @"
CILIUM_CLI_VERSION=\$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/\${CILIUM_CLI_VERSION}/cilium-linux-\${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-\${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-\${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-\${CLI_ARCH}.tar.gz{,.sha256sum}
"@

# Install Cilium
ssh k8s-control "cilium install --version 1.16.5"

# Wait for Cilium to be ready
ssh k8s-control "cilium status --wait"

# Wait for CoreDNS to be ready
ssh k8s-control "kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=300s"
```

**Note:** Cilium provides advanced networking features including:
- eBPF-based networking and security
- Network policies
- Load balancing
- Observability with Hubble

### Step 4: Get Join Command

```powershell
Write-Host "`nGenerating join command for worker nodes..." -ForegroundColor Green

$joinCommand = ssh k8s-control "kubeadm token create --print-join-command"

Write-Host "`nJoin Command:" -ForegroundColor Yellow
Write-Host $joinCommand -ForegroundColor Cyan

# Save join command
$joinCommand | Out-File -FilePath "$env:USERPROFILE\k8s-join-command.txt"
Write-Host "`nJoin command saved to: $env:USERPROFILE\k8s-join-command.txt" -ForegroundColor Green
```

### Step 5: Join Worker Nodes

```powershell
Write-Host "`nJoining worker nodes to cluster..." -ForegroundColor Green

# Join worker1
Write-Host "Joining k8s-worker1..." -ForegroundColor Green
ssh k8s-worker1 "sudo $joinCommand"

# Join worker2
Write-Host "Joining k8s-worker2..." -ForegroundColor Green
ssh k8s-worker2 "sudo $joinCommand"

# Wait a moment for nodes to register
Start-Sleep -Seconds 10

# Verify cluster
ssh k8s-control "kubectl get nodes"
```

### Step 6: Label Worker Nodes

```powershell
ssh k8s-control "kubectl label node k8s-worker1 node-role.kubernetes.io/worker=worker"
ssh k8s-control "kubectl label node k8s-worker2 node-role.kubernetes.io/worker=worker"
```

---

## Phase 7: Post-Installation Configuration

### Step 1: Copy kubeconfig to Windows

```powershell
# Create .kube directory on Windows
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.kube"

# Copy kubeconfig from control plane
scp k8s-control:~/.kube/config "$env:USERPROFILE\.kube\config"

Write-Host "Kubeconfig copied to: $env:USERPROFILE\.kube\config" -ForegroundColor Green
```

### Step 2: Install kubectl on Windows

```powershell
# Download kubectl
$kubectlVersion = "v1.31.0"
$kubectlUrl = "https://dl.k8s.io/release/$kubectlVersion/bin/windows/amd64/kubectl.exe"

# Download to a directory in PATH (e.g., C:\Windows\System32 or create custom dir)
$kubectlPath = "$env:USERPROFILE\bin"
New-Item -ItemType Directory -Force -Path $kubectlPath

Invoke-WebRequest -Uri $kubectlUrl -OutFile "$kubectlPath\kubectl.exe"

# Add to PATH if not already
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$kubectlPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$kubectlPath", [EnvironmentVariableTarget]::User)
}

# Verify kubectl
kubectl version --client
```

### Step 3: Test Cluster Access from Windows

```powershell
# Get nodes
kubectl get nodes

# Get all pods
kubectl get pods -A

# Get cluster info
kubectl cluster-info
```

### Step 4: Create Test Deployment

```powershell
# Create nginx deployment
kubectl create deployment nginx --image=nginx --replicas=3

# Check deployment
kubectl get deployments
kubectl get pods -o wide

# Expose deployment
kubectl expose deployment nginx --port=80 --type=NodePort

# Get service
kubectl get svc nginx

# Clean up
kubectl delete deployment nginx
kubectl delete service nginx
```

---

## Useful PowerShell Scripts

### Create VM Management Script

Save as `Manage-K8sCluster.ps1`:

```powershell
# Kubernetes Cluster Management Script

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('start','stop','status','restart','snapshot','restore')]
    [string]$Action,
    
    [string]$SnapshotName = "snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)

$nodes = @("k8s-control", "k8s-worker1", "k8s-worker2")

switch ($Action) {
    'start' {
        foreach ($node in $nodes) {
            Write-Host "Starting $node..." -ForegroundColor Green
            VBoxManage startvm $node --type headless
        }
    }
    'stop' {
        foreach ($node in $nodes) {
            Write-Host "Stopping $node..." -ForegroundColor Yellow
            VBoxManage controlvm $node poweroff
        }
    }
    'status' {
        foreach ($node in $nodes) {
            Write-Host "`nStatus of $node:" -ForegroundColor Cyan
            VBoxManage showvminfo $node | Select-String "State:"
        }
    }
    'restart' {
        foreach ($node in $nodes) {
            Write-Host "Restarting $node..." -ForegroundColor Yellow
            VBoxManage controlvm $node reset
        }
    }
    'snapshot' {
        foreach ($node in $nodes) {
            Write-Host "Creating snapshot for $node..." -ForegroundColor Green
            VBoxManage snapshot $node take $SnapshotName
        }
    }
    'restore' {
        foreach ($node in $nodes) {
            Write-Host "Restoring snapshot for $node..." -ForegroundColor Yellow
            VBoxManage snapshot $node restore $SnapshotName
        }
    }
}

# Usage:
# .\Manage-K8sCluster.ps1 -Action start
# .\Manage-K8sCluster.ps1 -Action stop
# .\Manage-K8sCluster.ps1 -Action snapshot -SnapshotName "fresh-install"
# .\Manage-K8sCluster.ps1 -Action restore -SnapshotName "fresh-install"
```

### Create Cluster Command Execution Script

Save as `Invoke-K8sCommand.ps1`:

```powershell
# Execute command on all cluster nodes

param(
    [Parameter(Mandatory=$true)]
    [string]$Command
)

$nodes = @("k8s-control", "k8s-worker1", "k8s-worker2")

foreach ($node in $nodes) {
    Write-Host "`n===================================" -ForegroundColor Cyan
    Write-Host "Executing on: $node" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    ssh $node $Command
}

# Usage:
# .\Invoke-K8sCommand.ps1 -Command "uptime"
# .\Invoke-K8sCommand.ps1 -Command "sudo systemctl status kubelet"
# .\Invoke-K8sCommand.ps1 -Command "free -h"
```

---

## Troubleshooting

### Check VM Status

```powershell
# List all VMs
VBoxManage list vms

# List running VMs
VBoxManage list runningvms

# Show VM details
VBoxManage showvminfo k8s-control
```

### Check Cluster Status

```powershell
# From Windows (if kubectl configured)
kubectl get nodes
kubectl get pods -A

# From control plane
ssh k8s-control "kubectl get componentstatuses"
ssh k8s-control "kubectl get pods -n kube-system"
```

### View Logs

```powershell
# kubelet logs
ssh k8s-control "sudo journalctl -u kubelet -f"

# containerd logs
ssh k8s-control "sudo journalctl -u containerd -f"
```

### Reset Cluster

```powershell
foreach ($node in @("k8s-control", "k8s-worker1", "k8s-worker2")) {
    ssh $node "sudo kubeadm reset -f && sudo rm -rf /etc/cni/net.d && sudo rm -rf ~/.kube/config"
}
```

---

## Network Configuration Summary

| Node | Hostname | MAC Address | IP Address | Role |
|------|----------|-------------|------------|------|
| VM1 | k8s-control | 08:00:27:00:00:10 | 192.168.56.10 | Control Plane |
| VM2 | k8s-worker1 | 08:00:27:00:00:11 | 192.168.56.11 | Worker |
| VM3 | k8s-worker2 | 08:00:27:00:00:12 | 192.168.56.12 | Worker |

**Host-Only Network**: 192.168.56.0/24
**Gateway**: 192.168.56.1
**DHCP**: Enabled with MAC-based IP reservations (192.168.56.100-200 range)
**Pod Network CIDR**: 10.244.0.0/16
**Service CIDR**: 10.96.0.0/12 (default)
**CNI Plugin**: Cilium (eBPF-based networking)

---

## Quick Reference Commands

```powershell
# Start cluster
VBoxManage startvm k8s-control --type headless
VBoxManage startvm k8s-worker1 --type headless
VBoxManage startvm k8s-worker2 --type headless

# Stop cluster
VBoxManage controlvm k8s-control poweroff
VBoxManage controlvm k8s-worker1 poweroff
VBoxManage controlvm k8s-worker2 poweroff

# SSH into nodes
ssh k8s-control
ssh k8s-worker1
ssh k8s-worker2

# Run kubectl from Windows
kubectl get nodes
kubectl get pods -A

# Create snapshot
VBoxManage snapshot k8s-control take "snapshot-name"
```

---

## Next Steps

1. Practice CKA exam topics
2. Create regular snapshots before major changes
3. Set up kubectl autocompletion in PowerShell (optional)
4. Configure persistent storage (optional)
5. Practice backup and restore procedures

---

**Installation Complete!** Your 3-node Kubernetes cluster is ready for CKA training on Windows.