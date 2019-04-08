#!/bin/bash
BSTRAP=/etc/.bootstrapped

if [ -f "${BSTRAP}" ]
then
  echo "System is already bootstrapped, exiting..."
  exit
fi

read -p "Enter new fqdn [c7inst.example.com]: " sysname
sysname=${sysname:-c7inst.example.com}

rm -rf /etc/ssh/ssh_host_*

nmcli con del "Wired connection 1"
mac=$(ip a show dev ens33 | grep link | awk '{ print $2 }')
nmcli con mod intern0 mac ${mac}
nmcli con up intern0

ip=$(getent hosts ${sysname} | awk '{ print $1 }')
if [ ! -z "${ip}" ]
then 
  echo && echo "Host ${sysname} has IP: ${ip}, configuring..."
  hostnamectl set-hostname ${sysname}
  nmcli con mod intern0 ipv4.address ${ip}/16
  nmcli con up intern0
  echo && echo "Updating system with latest packages..."
  yum -y update && echo "Finished configuration and updates, going to reboot in 5 seconds..." && touch ${BSTRAP} && sleep 5 && reboot
else 
  echo
  echo "Your hostname \"${sysname}\" is not visible in DNS!"
  echo "Please configure the IP address manually"
  echo
fi

touch ${BSTRAP}
