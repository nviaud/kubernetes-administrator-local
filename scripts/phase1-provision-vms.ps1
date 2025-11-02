# Kubernetes Cluster VM Provisioning Script
# Phase 1: VM Provisioning with VirtualBox CLI

Write-Host "=== Phase 1: VM Provisioning ===" -ForegroundColor Cyan

# Add VirtualBox to PATH
$env:Path += ";C:\Program Files\Oracle\VirtualBox"

# Step 1: Set Variables
$VMPath = "$env:USERPROFILE\VirtualBox VMs"
$ISOPath = "C:\Users\$env:USERNAME\Downloads\ubuntu-24.04.3-live-server-amd64.iso"

# Verify ISO exists
if (Test-Path $ISOPath) {
    Write-Host "ISO found at: $ISOPath" -ForegroundColor Green
} else {
    Write-Host "ISO not found! Please update path" -ForegroundColor Red
    exit 1
}

Write-Host "VM Path: $VMPath" -ForegroundColor Cyan
Write-Host ""

# Shared folder path (project directory)
$SharedPath = $PWD.Path
Write-Host "Using shared directory: $SharedPath" -ForegroundColor Green
Write-Host ""

# Step 3: Create Control Plane Node
Write-Host "Creating k8s-control VM..." -ForegroundColor Yellow

VBoxManage createvm --name k8s-control --ostype Ubuntu_64 --register --basefolder "$VMPath"

VBoxManage modifyvm k8s-control `
  --memory 2048 `
  --cpus 2 `
  --nic1 nat `
  --nic2 hostonly `
  --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" `
  --macaddress2 080027000010

VBoxManage createhd --filename "$VMPath\k8s-control\k8s-control.vdi" --size 20480

VBoxManage storagectl k8s-control --name "SATA Controller" --add sata --controller IntelAhci

VBoxManage storageattach k8s-control `
  --storagectl "SATA Controller" `
  --port 0 `
  --device 0 `
  --type hdd `
  --medium "$VMPath\k8s-control\k8s-control.vdi"

VBoxManage storageattach k8s-control `
  --storagectl "SATA Controller" `
  --port 1 `
  --device 0 `
  --type dvddrive `
  --medium "$ISOPath"

VBoxManage modifyvm k8s-control --boot1 dvd --boot2 disk --boot3 none --boot4 none

VBoxManage modifyvm k8s-control --nested-hw-virt on

VBoxManage sharedfolder add k8s-control `
  --name "k8s-shared" `
  --hostpath "$SharedPath" `
  --automount `
  --auto-mount-point /mnt/shared

Write-Host "k8s-control created successfully" -ForegroundColor Green
Write-Host ""

# Step 4: Create Worker Node 1
Write-Host "Creating k8s-worker1 VM..." -ForegroundColor Yellow

VBoxManage createvm --name k8s-worker1 --ostype Ubuntu_64 --register --basefolder "$VMPath"

VBoxManage modifyvm k8s-worker1 `
  --memory 2048 `
  --cpus 2 `
  --nic1 nat `
  --nic2 hostonly `
  --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" `
  --macaddress2 080027000011

VBoxManage createhd --filename "$VMPath\k8s-worker1\k8s-worker1.vdi" --size 20480

VBoxManage storagectl k8s-worker1 --name "SATA Controller" --add sata --controller IntelAhci

VBoxManage storageattach k8s-worker1 `
  --storagectl "SATA Controller" `
  --port 0 `
  --device 0 `
  --type hdd `
  --medium "$VMPath\k8s-worker1\k8s-worker1.vdi"

VBoxManage storageattach k8s-worker1 `
  --storagectl "SATA Controller" `
  --port 1 `
  --device 0 `
  --type dvddrive `
  --medium "$ISOPath"

VBoxManage modifyvm k8s-worker1 --boot1 dvd --boot2 disk --boot3 none --boot4 none

VBoxManage modifyvm k8s-worker1 --nested-hw-virt on

VBoxManage sharedfolder add k8s-worker1 `
  --name "k8s-shared" `
  --hostpath "$SharedPath" `
  --automount `
  --auto-mount-point /mnt/shared

Write-Host "k8s-worker1 created successfully" -ForegroundColor Green
Write-Host ""

# Step 5: Create Worker Node 2
Write-Host "Creating k8s-worker2 VM..." -ForegroundColor Yellow

VBoxManage createvm --name k8s-worker2 --ostype Ubuntu_64 --register --basefolder "$VMPath"

VBoxManage modifyvm k8s-worker2 `
  --memory 2048 `
  --cpus 2 `
  --nic1 nat `
  --nic2 hostonly `
  --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" `
  --macaddress2 080027000012

VBoxManage createhd --filename "$VMPath\k8s-worker2\k8s-worker2.vdi" --size 20480

VBoxManage storagectl k8s-worker2 --name "SATA Controller" --add sata --controller IntelAhci

VBoxManage storageattach k8s-worker2 `
  --storagectl "SATA Controller" `
  --port 0 `
  --device 0 `
  --type hdd `
  --medium "$VMPath\k8s-worker2\k8s-worker2.vdi"

VBoxManage storageattach k8s-worker2 `
  --storagectl "SATA Controller" `
  --port 1 `
  --device 0 `
  --type dvddrive `
  --medium "$ISOPath"

VBoxManage modifyvm k8s-worker2 --boot1 dvd --boot2 disk --boot3 none --boot4 none

VBoxManage modifyvm k8s-worker2 --nested-hw-virt on

VBoxManage sharedfolder add k8s-worker2 `
  --name "k8s-shared" `
  --hostpath "$SharedPath" `
  --automount `
  --auto-mount-point /mnt/shared

Write-Host "k8s-worker2 created successfully" -ForegroundColor Green
Write-Host ""

# Step 6: Configure DHCP Reservations
Write-Host "Configuring DHCP reservations..." -ForegroundColor Yellow

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

# Add MAC-to-IP reservations
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

Write-Host "DHCP reservations configured:" -ForegroundColor Green
Write-Host "  k8s-control (08:00:27:00:00:10) -> 192.168.56.10" -ForegroundColor White
Write-Host "  k8s-worker1 (08:00:27:00:00:11) -> 192.168.56.11" -ForegroundColor White
Write-Host "  k8s-worker2 (08:00:27:00:00:12) -> 192.168.56.12" -ForegroundColor White
Write-Host ""

# Step 7: Start VMs
Write-Host "Starting VMs in GUI mode for installation..." -ForegroundColor Yellow

VBoxManage startvm k8s-control --type gui
VBoxManage startvm k8s-worker1 --type gui
VBoxManage startvm k8s-worker2 --type gui

Write-Host ""
Write-Host "=== VMs Started ===" -ForegroundColor Green
Write-Host ""
Write-Host "Please complete Ubuntu installation on EACH VM:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Set hostname:" -ForegroundColor Yellow
Write-Host "   - k8s-control, k8s-worker1, or k8s-worker2" -ForegroundColor White
Write-Host ""
Write-Host "2. Create user account:" -ForegroundColor Yellow
Write-Host "   - Username: k8s" -ForegroundColor White
Write-Host "   - Password: k8s" -ForegroundColor White
Write-Host ""
Write-Host "3. Network: Use DHCP (default)" -ForegroundColor Yellow
Write-Host "   IPs will be assigned automatically via DHCP reservations:" -ForegroundColor White
Write-Host "   - k8s-control: 192.168.56.10" -ForegroundColor White
Write-Host "   - k8s-worker1: 192.168.56.11" -ForegroundColor White
Write-Host "   - k8s-worker2: 192.168.56.12" -ForegroundColor White
Write-Host ""
Write-Host "4. *** CRITICAL: Enable OpenSSH Server ***" -ForegroundColor Red
Write-Host "   On 'Featured Server Snaps' screen, check [X] OpenSSH server" -ForegroundColor Red
Write-Host "   Without SSH, Phase 2 configuration will fail!" -ForegroundColor Red
Write-Host ""
