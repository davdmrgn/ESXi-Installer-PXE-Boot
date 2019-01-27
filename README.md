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


