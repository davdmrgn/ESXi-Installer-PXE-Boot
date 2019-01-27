# ESXi Installer PXE Boot
* Based on ESXi 6.7 [Reference](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.esxi.install.doc/GUID-21FF3053-F77C-49E6-81A2-9369B85F5D52.html)


## Hardware Requirements
* 2 CPU cores
* 4 GB RAM minimum, 8 GB recommended to run virtual machines
* 2 GB local storage


## Considerations
- [ ] Verify VLAN tagging can be used with minimal configuration or if access ports must be used


## Deploy TFTP/DHCP Server
* Install Ubuntu 18.04.1
* Update Ubuntu `sudo apt update && sudo apt upgrade -y`


## Install Required Packages
* Install dhcp server, tftp `sudo apt install tftp-hpa tftpd-hpa isc-dhcp-server -y`
* Remove unnecessary packages `sudo apt autoremove -y`
* Back up dhcp config file `sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.orig`
* Back up dhcp interface file `sudo cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.orig`
* Back up tftp config file `sudo cp /etc/default/tftpd-hpa /etc/default/tftpd-hpa.orig`
* Back up ethernet adapter config file `sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.orig`


## Copy ESXi Installer Files (Boot to ESXi Installer)
* Mount ESXi installer `sudo mount /dev/cdrom /mnt`
* Copy ESXi installer to TFTP directory `sudo cp -rf /mnt/* /var/lib/tftpboot`


## Verify TFTP configuration
* Edit/View tftpd-hpa: `sudo nano /etc/default/tftpd-hpa`
```
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
```

* Restart TFTP service: `sudo service tftpd-hpa restart`


## Verify DHCP Configuration
* Edit dhcpd.conf: `sudo nano /etc/dhcp/dhcpd.conf`
```
option domain-name "vsphere.local";
option domain-name-servers 192.168.x.1;
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

subnet 192.168.x.0 netmask 255.255.255.0 {
  range dynamic-bootp 192.168.x.10 192.168.x.250;
  option broadcast-address 192.168.x.255;
  option routers 192.168.x.254;
}

allow booting;
allow bootp;
filename = "/efi/boot/bootx64.efi";
```

* Edit isc-dhcp-server: `sudo nano /etc/default/isc-dhcp-server`
    * Update this line with the interface name: `INTERFACESv4="ens192"`
* Restart DHCP service: `sudo service isc-dhcp-server restart`


## Additional Notes

### ESXi Remote Kickstart in Home Lab
* VMware Fusion 11 on Mojave
* ESXi 6.7 running in VMware Fusion
  * 2 vCPU
  * 4 GB RAM
  * 1 NIC (Bridged)
  * 4 GB HD

#### Configure NFS Export for Kickstart File Hosting on MacOS
* On macOS, open Terminal
* Create/Edit exports file: `sudo nano /etc/exports`
    * Add a line with the path to the kickstart file with the appropriate network information: `/Users/Shared/nfs -maproot=root:wheel -network 192.168.1.0 -mask 255.255.255.0`
* Restart/Start nfsd service: `sudo nfsd restart`
* Check exports on local machine: `showmount -e`
* Check exports from remote machine: `showmount -e NFS-SERVER-NAME`

#### Create ESXi Kickstart File
```
# Accept the VMware End User License Agreement
vmaccepteula

# Clear paritions and install
clearpart --firstdisk --overwritevmfs
install --firstdisk --overwritevmfs

# Set the root password to 'vmware'
rootpw --iscrypted $1$1K0mLlK/$IaFKhssy6EEhoAn7K9848.

# Network Settings
network --bootproto=dhcp --addvmportgroup=1
reboot

# Firstboot section 1
%firstboot --interpreter=busybox
sleep 10

# Enter maintenance mode
vim-cmd hostsvc/maintenance_mode_enter

# Suppress shell warning
esxcli system settings advanced set -o /UserVars/SuppressShellWarning -i 1
esxcli system settings advanced set -o /UserVars/ESXiShellTimeOut -i 1

# Add DNS Nameservers to /etc/resolv.conf
#cat > /etc/resolv.conf << \DNS
#nameserver 192.168.0.1
#nameserver 192.168.0.2
#DNS

# vSwitch Configurations
esxcli network vswitch standard add --vswitch-name=vSwitch0
esxcli network vswitch standard uplink add --uplink-name=vmnic0 --vswitch-name=vSwitch0
esxcli network vswitch standard add --vswitch-name=vSwitch1
esxcli network vswitch standard portgroup add --portgroup-name="Internal Network" --vswitch-name=vSwitch1

# Firstboot Section 2
%firstboot --interpreter=busybox

# Disable IPv6
esxcli network ip set --ipv6-enabled=false

# Reboot
sleep 10
reboot
```
* Save file to NFS export directory `/Users/Shared/nfs/esx.ks`

#### Deploy ESXi
* Boot ESXi VM to 6.7 installer
* At boot, press SHIFT+O to apply boot options, deleting the existing options: `netdevice=vmnic0 bootproto=dhcp ks=nfs://NFS-SERVER-NAME-OR-IP/Users/Shared/nfs/esxi.ks`
