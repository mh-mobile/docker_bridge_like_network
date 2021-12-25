#!/usr/bin/env bash

# Network Namespaceの作成
sudo ip netns add ns1
sudo ip netns add ns2
sudo ip netns add ns3
sudo ip netns add router
sudo ip netns add wan

# 仮想インターフェースをNetwork Namespaceに割り当て
sudo ip link add ns1-veth0 type veth peer name ns1-br0
sudo ip link add ns2-veth0 type veth peer name ns2-br0
sudo ip link add ns3-veth0 type veth peer name ns3-br0
sudo ip link add gw-veth1 type veth peer name wan-veth0

# 仮想インターフェースをNetwork Namespaceに割り当て
sudo ip link set ns1-veth0 netns ns1
sudo ip link set ns2-veth0 netns ns2
sudo ip link set ns3-veth0 netns ns3
sudo ip link set ns1-br0 netns router
sudo ip link set ns2-br0 netns router
sudo ip link set ns3-br0 netns router
sudo ip link set gw-veth1 netns router
sudo ip link set wan-veth0 netns wan

# ブリッジの作成
sudo ip netns exec router ip link add dev br0 type bridge
sudo ip netns exec router ip link set ns1-br0 master br0
sudo ip netns exec router ip link set ns2-br0 master br0
sudo ip netns exec router ip link set ns3-br0 master br0

# 仮想インターフェースの有効化

## ns1
sudo ip netns exec ns1 ip link set ns1-veth0 up
sudo ip netns exec ns1 ip link set lo up

## ns2
sudo ip netns exec ns2 ip link set ns2-veth0 up
sudo ip netns exec ns2 ip link set lo up

## ns3
sudo ip netns exec ns3 ip link set ns3-veth0 up
sudo ip netns exec ns3 ip link set lo up

## router
sudo ip netns exec router ip link set ns1-br0 up
sudo ip netns exec router ip link set ns2-br0 up
sudo ip netns exec router ip link set ns3-br0 up
sudo ip netns exec router ip link set br0 up
sudo ip netns exec router ip link set lo up
sudo ip netns exec router ip link set gw-veth1 up

## wan
sudo ip netns exec wan ip link set wan-veth0 up
sudo ip netns exec wan ip link set lo up

# 仮想インターフェースにIPアドレスやルーティングの割り当て

## ns1
sudo ip netns exec ns1 ip address add 192.0.2.1/24 dev ns1-veth0
sudo ip netns exec ns1 ip route add default via 192.0.2.254
sudo ip netns exec ns1 ip link set ns1-veth0 address 00:00:5E:00:53:01

## ns2
sudo ip netns exec ns2 ip address add 192.0.2.2/24 dev ns2-veth0
sudo ip netns exec ns2 ip route add default via 192.0.2.254
sudo ip netns exec ns2 ip link set ns2-veth0 address 00:00:5E:00:53:02

## ns3
sudo ip netns exec ns3 ip address add 192.0.2.3/24 dev ns3-veth0
sudo ip netns exec ns3 ip route add default via 192.0.2.254
sudo ip netns exec ns3 ip link set ns3-veth0 address 00:00:5E:00:53:03

## router
sudo ip netns exec router ip address add 192.0.2.254/24 dev br0
sudo ip netns exec router ip address add 203.0.113.254/24 dev gw-veth1

## wan
sudo ip netns exec wan ip address add 203.0.113.1/24 dev wan-veth0
sudo ip netns exec wan ip route add default via 203.0.113.254

# ルーターのIPフォワーディングの有効化
sudo ip netns exec router sysctl net.ipv4.ip_forward=1

# ルーターのループバックアドレスの転送設定の有効化
sudo ip netns exec router sysctl net.ipv4.conf.all.route_localnet=1

# iptablesのSource NAT（IPマスカレード）の設定
sudo ip netns exec router iptables -t nat  \
      -A POSTROUTING \
      -s 192.0.2.0/24 \
      -o gw-veth1 \
      -j MASQUERADE

# iptablesのDestination NATの設定
sudo ip netns exec router iptables -t nat \
      -A PREROUTING \
      --dst 203.0.113.254 \
      -p tcp \
      --dport 80 \
      -j DNAT \
      --to-destination 192.0.2.2:80

sudo ip netns exec router iptables -t nat \
      -A OUTPUT \
      --dst 203.0.113.254 \
      -p tcp \
      --dport 80 \
      -j DNAT \
      --to-destination 192.0.2.2:80

sudo ip netns exec router iptables -t nat \
      -A OUTPUT \
      --dst 127.0.0.1 \
      -p tcp \
      --dport 80 \
      -j DNAT \
      --to-destination 192.0.2.2:80

sudo ip netns exec router iptables -t nat \
      -A POSTROUTING \
      -p tcp \
      --dst 192.0.2.2 \
      --dport 80 \
      -j SNAT \
      --to-source 203.0.113.254
