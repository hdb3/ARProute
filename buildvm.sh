#!/bin/bash -xe
export vm=$1 memsize=$2 cpucount=$3 sourceimage=CentOS-7-x86_64-GenericCloud pool=libvirt
virsh vol-clone --pool $pool $sourceimage ${vm}
virt-install --name $vm --memory $memsize --vcpus $cpucount --disk vol=$pool/${vm} --import --os-variant rhel7 --noautoconsole
export remoteip=`vm2ip $vm`
echo "IP for $vm is $remoteip"
printf "server localdns 8053 \n update del ${vm}.virt \n send \n answer \n" | nsupdate
printf "server localdns 8053 \n update add ${vm}.virt 86400 A ${remoteip} \n send \n answer \n" | nsupdate
fping ${vm}.virt
ssh centos@${vm} sudo yum -y check-update || echo "non-zero return ignored"
ssh centos@${vm} sudo "curl -fsSL https://get.docker.com/ | sh"
ssh centos@${vm} sudo "sed -i.original -e'/^ExecStart=\/usr\/bin\/dockerd/s/$/ -H tcp:\/\/0.0.0.0:2375/' /usr/lib/systemd/system/docker.service"
scp daemon.json centos@${vm}:
ssh centos@${vm} sudo install -D daemon.json /etc/docker/daemon.json
ssh centos@${vm} sudo systemctl enable --now docker
ssh centos@${vm} sudo docker info
DOCKER_HOST=${vm} docker info
scp arproute.tgz centos@${vm}:
ssh centos@${vm} "tar xzf arproute.tgz && sudo install arproute/arprouted /usr/sbin && sudo install arproute/arproute.service /usr/lib/systemd/system && sudo systemctl enable --now arproute"
