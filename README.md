# ARProute
bindings for some of the functions available in iproute2

additionally, ARP routing via arpping

the purpose is to enable routed connectivity over unnumbered network interfaces, using host loopback addresses

this simplifies configuration in complex virtual topologies

## Motivation
We wish to enable virtualised routers to communicate without prior topology specific configuration.
Typically this requires connectivity to addresses which are not on shared subnets, and thus must be 'routed', either over a default interface or a specifically chosen one.
This project enable routers with interfaces which share a  layer 2 broadcast channel to discover and utilise those paths to communicate without manual configuration.
## Usage
### Client
Run ARProuter as a daemon on clients, having previously defined a unique loopback address (ip addr add x.x.x.x/32 dev lo).
### Host
In the host environment Mesh takes a list of VMs and generates scripts which will create and attach virtual point to point links between the given VMs.  The scripts use a combination of _virsh_ and _ip route_ CLI commands.  Mesh also generates the commands required to undo the configuration which it defines.
## Architecture
ARProuter clients run the application ARProuter as a daemon.  ARProuter performs two roles: talker and listener.  As talker it send periodic ARP advertisements of its own loopback address.  As listener it discovers  advertised routes from other peer ARProuter broadcasts, and installs routes to these peers in the L3 route table.
## Project Structure
The main executable is ARProuter, and the network utility functions which it uses are in _module_  IPRoute.
A complementary utility is Mesh, which works with the libvirt/virsh infrastructure and uses functiosn defined in VirtMesh and VirtXML.  VirtMesh adds interfaces and links to virtual machines which can then be utilised by VMs running ARProuter.
