# Accept the VMware End User License Agreement
vmaccepteula

# Clear paritions and install
clearpart --firstdisk --overwritevmfs
install --firstdisk --overwritevmfs --novmfsondisk

# Set the root password to 'vmware'
rootpw --iscrypted $1$1K0mLlK/$IaFKhssy6EEhoAn7K9848.  # openssl passwd -1 "vmware"
#rootpw vmware  # Passwords in clear text must meet complexity requirements

# Network Settings
network --bootproto=dhcp --addvmportgroup=1
reboot

# Commands to run on first boot
%firstboot --interpreter=busybox

# Configure NTP
cat >> /etc/ntp.conf << EOF
server time.nist.gov
EOF
chkconfig ntpd on
/etc/init.d/ntpd restart

# Set ESXi Options
esxcli system settings advanced set -o /UserVars/SuppressShellWarning -i 1  # Suppress shell warning
vim-cmd hostsvc/enable_ssh  # Enable SSH
vim-cmd hostsvc/enable_esx_shell  # Enable shell from console
esxcli system settings advanced set -o /UserVars/HostClientCEIPOptIn -i 2  # CEIP opt-out
MAC="esx-$(esxcli network nic get -n vmnic0 | grep 'Virtual Address:' | awk {'print $3'} | sed -r 's/://g' | cut -c 9-12)"  # Capture end of MAC address of vmnic0 without colons
esxcli system settings advanced set -o /Misc/PreferredHostName -s $MAC  # Set Hostname based on vmnic0 MAC address

# vSwitch Configurations
#esxcli network vswitch standard add --vswitch-name=vSwitch0
esxcli network vswitch standard uplink add --uplink-name=vmnic0 --vswitch-name=vSwitch0
esxcli network vswitch standard add --vswitch-name=vSwitch1
esxcli network vswitch standard portgroup add --portgroup-name="Internal Network" --vswitch-name=vSwitch1

# Rename mounted datastore
vim-cmd hostsvc/datastore/rename remote-install-location nfs

# Disable IPv6
esxcli network ip set --ipv6-enabled=false

# Reboot
sleep 10
reboot