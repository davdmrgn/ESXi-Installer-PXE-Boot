# ESXi Installer PXE Boot

* Based on ESXi 6.7 [Reference](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.esxi.install.doc/GUID-21FF3053-F77C-49E6-81A2-9369B85F5D52.html)

## Hardware Requirements

* 2 CPU cores
* 4 GB RAM minimum, 8 GB recommended to run virtual machines
* 2 GB local storage

## Considerations

* [ ] Verify VLAN tagging can be used with minimal configuration or if access ports must be used

## Deploy TFTP/DHCP Server

* Install Ubuntu 18.04.1
* Update Ubuntu `sudo apt update && sudo apt upgrade -y`
* Remove unnecessary packages `sudo apt autoremove -y`

## Install Required Packages

* Install dhcp server, tftp `sudo apt install tftp-hpa tftpd-hpa isc-dhcp-server -y`
* Back up dhcp config file `sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.orig`
* Back up dhcp interface file `sudo cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.orig`
* Back up tftp config file `sudo cp /etc/default/tftpd-hpa /etc/default/tftpd-hpa.orig`
* Back up ethernet adapter config file `sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.orig`

## Copy ESXi Installer Files (Boot to ESXi Installer)

* Mount ESXi installer `sudo mount /dev/cdrom /mnt`
* Copy ESXi installer to TFTP directory `sudo cp -rf /mnt/* /var/lib/tftpboot`
* Unmount ESXi CDROM `sudo umount /mnt`

## Verify TFTP configuration

* Verify tftpd-hpa: `cat /etc/default/tftpd-hpa`

  ``` bash
  TFTP_USERNAME="tftp"
  TFTP_DIRECTORY="/var/lib/tftpboot"
  TFTP_ADDRESS=":69"
  TFTP_OPTIONS="--secure"
  ```

* Restart TFTP service (if needed): `sudo service tftpd-hpa restart`

## Verify DHCP Configuration

* Edit dhcpd.conf for a specific hardware type: `sudo nano /etc/dhcp/dhcpd.conf`

  ``` bash
  sudo cat > /etc/dhcp/dhcpd.conf << EOF
  option domain-name "lan";
  option domain-name-servers 192.168.86.1;
  default-lease-time 3600;
  max-lease-time 3600;
  ddns-update-style none;
  not authoritative;
  allow booting;
  allow bootp;
  filename = "/efi/boot/bootx64.efi";

  class "VMware" {
    match if substring(option vendor-class-identifier, 0, 20) = "PXEClient:Arch:00007";
  }

  subnet 192.168.86.0 netmask 255.255.255.0 {
    pool {
      allow members of "VMware";
      range dynamic-bootp 192.168.86.100 192.168.86.199;
      option broadcast-address 192.168.86.255;
      option routers 192.168.86.1;
    }
  }
  EOF
  ```

* Start/Restart DHCP service: `sudo service isc-dhcp-server restart`

## Additional Notes

### ESXi Remote Kickstart in Home Lab

* VMware Fusion 11 on Mojave
* ESXi 6.7 running in VMware Fusion
  * 2 vCPU
  * 4 GB RAM
  * 1 NIC (Bridged)
  * 2 GB HD

#### Configure NFS Export for Kickstart File Hosting on MacOS

* On macOS, open Terminal
* Create/Edit exports file: `sudo nano /etc/exports`
  * Add a line with the path to the kickstart file with the appropriate network information: `/Users/Shared/nfs -network 192.168.1.0 -mask 255.255.255.0`

  `/Users/Shared/nfs -alldirs -mapall=0 -network 192.168.86.0 -mask 255.255.255.0`

* Restart/Start nfsd service: `sudo nfsd restart`
* Check exports on local machine: `showmount -e`
* Check exports from remote machine: `showmount -e NFS-SERVER-NAME`

#### Create ESXi Kickstart File

* [esx.ks](./esx.ks)
* Save file to NFS export directory `/Users/Shared/nfs/esx.ks`

#### Deploy ESXi

* Boot ESXi VM to 6.7 installer
* At boot, press SHIFT+O to apply boot options, deleting the existing options: `netdevice=vmnic0 bootproto=dhcp ks=nfs://NFS-SERVER-NAME-OR-IP/Users/Shared/nfs/esxi.ks`

#### Deploy ESXi from PXE Boot using Kickstart File

Edit boot.cfg kernelopt to include kickstart path

* Back up boot.cfg file `sudo cp /var/lib/tftpboot/efi/boot/boot.cfg /var/lib/tftpboot/efi/boot/boot.cfg.orig`
* Edit the kernelopt line to include kickstart file from NFS share `sudo sed -i 's/runweasel/ks=nfs:\/\/NFS-SERVER-NAME-OR-IP\/Users\/Shared\/nfs\/esxi.ks/g' /var/lib/tftpboot/efi/boot/boot.cfg`

## Deploy PSC from Mac via CLI Installer

The instructions below creates a PSC VM with 2 vCPU, 4 GB RAM, ~60 GB disk space

* Mount `VMware-VMvisor-Installer-6.x.x.x86_64` ISO
* Copy and edit `/vcsa-cli-installer/templates/PSC_first_instance_on_ESXi.json` to a local path
* From mounted CDROM, execute `/vcsa-cli-installer/mac/vcsa-deploy install ~/Downloads/PSC_first_instance_on_ESXi.json --accept-eula`
* Wait for installation to complete
* PSC requires reverse DNS entry for hostname

## Deploy VCSA from Mac via CLI Installer

The instructions below creates a VCSA VM with 2 vCPU, 10 GB RAM, ~230 GB disk space

* Mount `VMware-VMvisor-Installer-6.x.x.x86_64` ISO
* Copy and edit `/vcsa-cli-installer/templates/vCSA_on_ESXi.json` to a local path
* From mounted CDROM, execute `/vcsa-cli-installer/mac/vcsa-deploy install ~/Downloads/vCSA_on_ESXi.json --accept-eula`
* VCSA installation failed; most likely due to DNS