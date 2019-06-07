#!/bin/bash -xe
export vm=$1 memsize=$2 cpucount=$3 sourceimage=CentOS-7-x86_64-GenericCloud pool=libvirt
#export vm=h55 memsize=2048 cpucount=1 sourceimage=CentOS-7-x86_64-GenericCloud.qcow2 pool=libvirt
echo "virsh vol-clone --pool $pool $sourceimage ${vm}"
virsh vol-clone --pool $pool $sourceimage ${vm}
echo "virt-install --name $vm --memory $memsize --vcpus $cpucount --disk ${vm} --import --os-variant rhel7 --noautoconsole"
virt-install --name $vm --memory $memsize --vcpus $cpucount --disk vol=$pool/${vm} --import --os-variant rhel7 --noautoconsole
export remoteip=`vm2ip $vm`
echo "IP for $vm is $remoteip"
printf "server big 8053 \n update add ${vm}.virt 86400 A ${remoteip} \n send\n" | nsupdate
fping ${vm}.virt
ssh centos@${vm} sudo yum -y update 
ssh centos@${vm} sudo yum -y install docker
scp docker-network centos@${vm}:
ssh centos@${vm} sudo mv docker-network /etc/sysconfig/docker-network
ssh centos@${vm} sudo systemctl enable --now docker
ssh centos@${vm} sudo docker info
DOCKER_HOST=${vm} docker info
