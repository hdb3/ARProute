#!/bin/bash
export vm=$1 memsize=$2 cpucount=$3 sourceimage=CentOS-7-x86_64-GenericCloud.qcow2 pool=libvirt
#export vm=h55 memsize=2048 cpucount=1 sourceimage=CentOS-7-x86_64-GenericCloud.qcow2 pool=libvirt
echo "virsh vol-clone --pool $pool $sourceimage ${vm}.qcow2"
virsh vol-clone --pool $pool $sourceimage ${vm}.qcow2
echo "virt-install --name $vm --memory $memsize --vcpus $cpucount --disk ${vm}.qcow2 --import --os-variant rhel7 --noautoconsole"
virt-install --name $vm --memory $memsize --vcpus $cpucount --disk vol=$pool/${vm}.qcow2 --import --os-variant rhel7 --noautoconsole
export remoteip=`vm2ip $vm`
echo "IP for $vm is $remoteip"
#echo "IP for $vm is `vm2ip $vm` "
ssh centos@${remoteip} sudo yum -y update 
ssh centos@${remoteip} sudo yum -y install docker
scp docker-network centos@${remoteip}:
ssh centos@${remoteip} sudo mv docker-network /etc/sysconfig/docker-network
ssh centos@${remoteip} sudo systemctl enable --now docker
ssh centos@${remoteip} sudo docker info
DOCKER_HOST=${remoteip} docker info
printf "server big 8053 \n update add ${vm}.virt 86400 A ${remoteip} \n send\n" | nsupdate
ping ${vm}.virt
