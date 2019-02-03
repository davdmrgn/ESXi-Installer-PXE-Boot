# ESXi Lab

Deploy ESXi 6.5

* 8 CPU
* 20 GB RAM
* 400 GB disk
* Bridged Network (in Fusion) - 1 NIC
  * 1 vSwitch
    * 2 Portgroups:
      * Management - Static IP: 192.168.86.2/24|.1
      * VM Network

## Deploy DNS Server

On ESXi host, deploy Ubuntu VM.

* Ubuntu server 18
* 1 vCPU
* 1 GB RAM
* 16 GB HD
* PV SCSI Controller
* VMXNET3 - VM Network: 192.168.86.3
* Hostname: `dns`
* _In ESX_ domain name: `dm.lab`
* Update: `sudo apt update && sudo apt upgrade -y`
* Install `dnsmasq`: `sudo apt install dnsmasq`
* Update `/etc/hosts` with esx, psc, vcsa names and IP addresses (with _dm.lab_ domain name)
* Update `/etc/dnsmasq.conf` file
  * Uncomment and update `domain` line: `domain=dm.lab`
* Start `dnsmasq` service: `sudo service dnsmasq start`

* A reboot is required

## Deploy PSC from Mac via CLI Installer

The instructions below creates a PSC VM with 2 vCPU, 4 GB RAM, ~60 GB disk space

* Mount `VMware-VMvisor-Installer-6.x.x.x86_64` ISO
* Copy and edit `/Volumes/CDROM/vcsa-cli-installer/templates/install/PSC_first_instance_on_ESXi.json`
* From mounted CDROM, execute `/Volumes/CDROM/vcsa-cli-installer/mac/vcsa-deploy install ~/Downloads/PSC_first_instance_on_ESXi.json --accept-eula`
* Wait for installation to complete

## Deploy VCSA from Mac via CLI Installer

The instructions below creates a VCSA VM with 2 vCPU, 10 GB RAM, ~230 GB disk space

* Mount `VMware-VMvisor-Installer-6.x.x.x86_64` ISO
* Copy and edit `/Volumes/CDROM/vcsa-cli-installer/templates/install//vCSA_on_ESXi.json`
* From mounted CDROM, execute `/Volumes/CDROM/vcsa-cli-installer/mac/vcsa-deploy install ~/Git/ESXi-Installer-PXE-Boot/vCSA_on_ESXi.json --accept-eula`
* Install finished successfully