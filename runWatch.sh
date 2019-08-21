#!/bin/bash
runWatchRelDir=$(dirname "${BASH_SOURCE[0]}")
runWatchRelDir=$(realpath $runWatchRelDir)
source ${runWatchRelDir}/debugLogger.sh;

counter=1
ip=${flags[ip]}
port=${flags[port]}
interval=${flags[interval]}
cmd=${flags[cmd]}
boot=${flags[boot]}
reboot=${flags[reboot]}

if [ -z "$ip" ] || [ -z "$port" ] || [ -z "$interval" ] ||
    [ -z "$cmd" ] || [ -z "$boot" ] || [ -z "$reboot" ]
then
  echo runWatch.sh -ip \"\" -port \"\" -interval \"\" -cmd \"\" -boot \"\" -reboot \"\"
else
  while [ $counter -le 10 ]
  do
  		serverNotRunning=$(nping -c 1 -p $port $ip | grep "Successful connections: 0")
  		if [ "$serverNotRunning" ]; then
        $cmd
        echo Stopped running at $(date +"%Y-%m-%d_%H-%M-%S") >> ./runWatch.log
  			sleep $boot
        stillNotRunning=$(nping -c 1 -p $port $ip | grep "Successful connections: 0")
        echo Initiated reboot at $(date +"%Y-%m-%d_%H-%M-%S") >> ./runWatch.log
        $reboot
      fi
  	sleep $interval
  done
fi
