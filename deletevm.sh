#!/bin/bash -xe
export vm=$1 pool=libvirt
export remoteip=`vm2ip $vm`
echo "virsh destroy $vm"
virsh destroy $vm
echo "virsh undefine $vm"
virsh undefine $vm
echo "virsh vol-delete --pool $pool ${vm}"
virsh vol-delete --pool $pool ${vm}
echo "server big 8053 \n update del ${vm}.virt 86400 A ${remoteip} \n send\n \| nsupdate"
printf "server big 8053 \n update del ${vm}.virt 86400 A ${remoteip} \n send\n" | nsupdate
