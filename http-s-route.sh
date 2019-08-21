#!/usr/bin/env bash

# Author: https://serverfault.com/users/35520/misha
# Location: https://serverfault.com/questions/112795/how-to-run-a-server-on-port-80-as-a-normal-user-on-linux
httpSrouteDir=$(dirname "${BASH_SOURCE[0]}")
httpSrouteDir=$(realpath $mcRelDir)
source ${httpSrouteDir}/commandParser.sh;

iptables -t mangle -A PREROUTING -p tcp --dport 80 -j MARK --set-mark 1
iptables -t mangle -A PREROUTING -p tcp --dport 443 -j MARK --set-mark 1
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port ${flags['http']}
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port ${flags['https']}
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${flags['http']} -m mark --mark 1 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${flags['https']} -m mark --mark 1 -j ACCEPT
