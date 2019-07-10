#!/bin/bash -x
set +e
export vm=$1 pool=libvirt
export remoteip=`vm2ip $vm`
virsh destroy $vm
virsh undefine $vm
virsh vol-delete --pool $pool ${vm}
