# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug enp1s0
iface enp1s0 inet dhcp

auto enp7s0
iface enp7s0 inet static
        address 10.5.5.1
        network 10.5.5.0
        netmask 255.255.255.0
        broadcast 10.5.5.255
