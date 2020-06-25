sudo iptables -I INPUT -p tcp --dport $1 -j ACCEPT
