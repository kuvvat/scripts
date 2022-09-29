#!/bin/bash
#usage ssh ip-address 'bash -s' < add_user.sh

sudo -i
users=("kgm")
keys=("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCLXPtWhqqYTy5VhyWQOMCIvllprfQHINujzriav2YQkx6wcnB4sod1ETXl091LiR1uKVQqV+tnix71/6sqh/XzT1Z6/qKZFkypnctNCIQi+xChsg91/ixOA9acqm61oWexY18HXljt2wVlDtjcGV4EPxTPtZ3ATn")
for i in ${!users[*]};do
    echo "${users[$i]}'s key is ${keys[$i]}"
    useradd ${users[$i]} -d /home/${users[$i]} -p ua5yaing8MuquethaiPh
    mkdir -p /home/${users[$i]}/.ssh
    echo ${keys[$i]} >> /home/${users[$i]}/.ssh/authorized_keys
    chmod 600 /home/${users[$i]}/.ssh/authorized_keys
    chown -R ${users[$i]} /home/${users[$i]}
    echo "${users[$i]}  ALL = (ALL) NOPASSWD:ALL" >> /etc/sudoers
done
