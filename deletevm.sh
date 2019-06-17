#!/bin/bash -x
export vm=$1 pool=libvirt
export remoteip=`vm2ip $vm`
virsh destroy $vm
virsh undefine $vm
virsh vol-delete --pool $pool ${vm}
