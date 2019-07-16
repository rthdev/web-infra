#!/bin/bash
BSTRAP=/etc/.bootstrapped
USERNAME="rtcadm"
USER_SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDi4sop1jRfwyfoPfQnUUrTJM2xFNi6s8Tzyfy8nWGNgDRWcuASDPXJce5hvo7AJBh+YUntkb6qlm+KVpXfzEiCAzTJoyYWQkYzVHzFYQvhqWsaGe2/JfzFroe3D/mVjPEdKHHaqwCHrIJjMlMGbF0f76k6Jgmximd56qo6cE803apZaNVAzjNtBfU5ng8J6t07kJGmQcdy/SpF4m4RQCFIgaunMl2zv1eO/0KL8Q1V/CTHtqdTbgNHeYaI6uD/Tow49lE7xEEZvgJ/BdM5W4wfd+2XqpYlPNK/jP2qYYeP+O1pRFgbZV0jmtnvNILVK36tvyQUXiUzp5TMyjJ/NnIM82SEfbwpqEGNkjvq3SI8b94eQB7O4d7dLAJusLQlVDcJO5kpYoAlhlKjFM1fUdRT+YWNyD/zCOGMVFP4ravT/gNRlM/inI83pAgcELj7UnsIyPVt90HF9on52vK5pyL42nTmT4ADrlL8sjhNgwKj0kQpk1pI74CW/Z7NM/fuc6stjrpDofael9Ie7FrSUjDAP7tARtVMct8HcX2580S9bIEZGYhYrOHZu0lNqAEggvOVohBWP8ABSVW18UgGapz8bDjPuwA5wGk5/90mo94D1knWk5MyhAIvUF9yicyRoe8GwKm/dlRRBzriBX6rgVJ6ce7d5NHH1MLEzgogZIk0Qw== ${USERNAME}@infra.example.com"

if [ -f "${BSTRAP}" ]
then
  echo "System is already bootstrapped, exiting..."
  exit
fi

read -p "Enter new fqdn [c7inst.example.com]: " sysname
sysname=${sysname:-c7inst.example.com}
echo "\nConfiguring Hostname: ${sysname}...\n"

rm -rf /etc/ssh/ssh_host_*

nmcli con mod ens33 connection.id intern0

#nmcli con del "Wired connection 1"
#mac=$(ip a show dev ens33 | grep link | awk '{ print $2 }')
#nmcli con mod intern0 mac ${mac}
#nmcli con up intern0

mkdir -p /home/${USERNAME}/.ssh
chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh

echo ${USER_SSH_KEY} > /home/${USERNAME}/.ssh/authorized_keys

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
