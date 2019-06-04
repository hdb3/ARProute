#!/bin/bash
export vm=$1 memsize=$2 cpucount=$3 sourceimage=CentOS-7-x86_64-GenericCloud.qcow2 pool=libvirt
#export vm=h55 memsize=2048 cpucount=1 sourceimage=CentOS-7-x86_64-GenericCloud.qcow2 pool=libvirt
echo "virsh vol-clone --pool $pool $sourceimage ${vm}.qcow2"
virsh vol-clone --pool $pool $sourceimage ${vm}.qcow2
echo "virt-install --name $vm --memory $memsize --vcpus $cpucount --disk ${vm}.qcow2 --import --os-variant rhel7 --noautoconsole"
virt-install --name $vm --memory $memsize --vcpus $cpucount --disk vol=$pool/${vm}.qcow2 --import --os-variant rhel7 --noautoconsole
echo "IP for $vm is `./vm2ip $vm` "
./vm2ip $vm
