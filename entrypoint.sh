#!/bin/sh

grepzt() {
  (find /proc -name exe | xargs -I{} readlink {}) 2>/dev/null | grep -q zerotier-one
  return $?
}

echo "starting zerotier"
setsid /usr/sbin/zerotier-one &

while ! grepzt
do
  echo "zerotier hasn't started, waiting a second"
  sleep 1
done

# Set IPTables to allow NATting
sysctl -w net.ipv4.ip_forward=1 > /dev/null

echo "joining networks: $ZT_NETWORKS"

for n in $ZT_NETWORKS
do
  echo "joining $n"

  while ! zerotier-cli join "$n"
  do 
    echo "joining $n failed; trying again in 1s"
    sleep 1
  done

  if [ "$ZT_BRIDGE" = "true" ]
  then
    echo "Configuring iptables on $(zerotier-cli get $n portDeviceName)"
    PHY_IFACE=ovs_eth0; ZT_IFACE=$(zerotier-cli get $n portDeviceName)

    iptables -t nat -A POSTROUTING -o $PHY_IFACE -j MASQUERADE
    #nft add rule ip nat POSTROUTING oifname "$PHY_IFACE" counter masquerade
    iptables -t nat -A POSTROUTING -o $ZT_IFACE -j MASQUERADE
    #nft add rule ip nat POSTROUTING oifname "$ZT_IFACE" counter masquerade
    iptables -A FORWARD -i $PHY_IFACE -o $ZT_IFACE -j ACCEPT
    #nft add rule ip filter FORWARD iifname "$PHY_IFACE" oifname "$ZT_IFACE" counter accept
    iptables -A FORWARD -i $ZT_IFACE -o $PHY_IFACE -j ACCEPT
    #nft add rule ip filter FORWARD iifname "$ZT_IFACE" oifname "$PHY_IFACE" counter accept
  fi
done

# Give ZT a second realise it's online
sleep 10

# Print Client Info
echo "$(zerotier-cli info)"

sleep infinity
