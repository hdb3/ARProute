# iproute2
bindings for some of the functions available in iproute2

additionally, ARP transmission via arpping

the purpose is to allow routing over unnumbered network interfaces, using host loopback addresses

this simplifies configuration in complex virtual topologies

## Motivation
We wish to enable virtualised routers to communicate without prior topology specific configuration.
Typically this requires connectivity to addresses which are not on shared subnets, and thus must be 'routed', either over a default interface or a specifically chosen one.
This project enable routers with interfaces which share a  layer 2 broadcast channel to discover and utilise those paths to communicate without manual configuration.
