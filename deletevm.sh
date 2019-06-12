#!/bin/bash -x
export vm=$1 pool=libvirt
export remoteip=`vm2ip $vm`
virsh destroy $vm
virsh undefine $vm
virsh vol-delete --pool $pool ${vm}
printf "server big 8053 \n update del ${vm}.virt \n send\n" | nsupdate
