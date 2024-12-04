#!/usr/bin/env bash

# To use without password
# on local computer
# ssh-keygen                                    ---generate pub/private key
# eval "$(ssh-agent -s)"                        ---start ssh-agent (probably not nessisary but cant hurt)
# ssh-add [private-key]                         ---add private key to local
# ssh-copy-id -i [public-key] [user]@[ip]       ---register public key with remote computer

user="root"
cloudHost='134.209.123.38'
cloudPath="/root/ssh-transfer-test/*"
computerPath="/home/jozsef/ssh-transfer-test/"
sshCertPath='/home/jozsef/ssh-transfer-test/ssh-key'
timeInterval=15

count=0
while true; do
  scp -r -i $sshCertPath $user@$cloudHost:$cloudPath $computerPath 2> /dev/null
  if [ $? -eq 0 ]
  then
    ssh -i $sshCertPath $user@$cloudHost "rm -rf $cloudPath"
  fi;
  sleep $timeInterval;
done;
