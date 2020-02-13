#!/bin/bash

timeStampRelDir=$(dirname "${BASH_SOURCE[0]}")
timeStampRelDir=$(realpath $timeStampRelDir)
source ${timeStampRelDir}/debugLogger.sh;

rootDir=/home/$USER/Videos/
detailSize=32
timeSize=8

definitSize() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  local min=$1
  local max=$2
  local string=$3
  local justify=$4
  local spacer=$5

  test -z "$spacer" && spacer=' '

  local length=${#string}
  if [ $length -ge $max ]
  then
    echo "${string:0:$max}"
  elif [ $length -le $min ]
  then
    let "diff=$min-$length"
    back=''
    for (( i=1; i<=$(($diff/2)) ; i++ ))
    do
      back+=$spacer
    done
    front="$back"
    test $(($length%2)) != 0 && front="$back$spacer"

    if [ "$justify" == "l" ]
    then
      echo "$string$front$back"
    elif [ "$justify" == "r" ]
    then
      echo "$front$back$string"
    else
      echo "$front$string$back"
    fi
  else
    echo "$string"
  fi
}


#Stole conversion from http://www.unixcl.com/2009/01/convert-seconds-to-hour-minute-seconds.html
convertToRelTime() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  local S=${1}
  ((h=S/3600))
  ((m=S%3600/60))
  ((s=S%60))
  h=$(definitSize 2 2 $h r 0)
  m=$(definitSize 2 2 $m r 0)
  s=$(definitSize 2 2 $s r 0)
  echo "$h:$m:$s"
}

findTimeStampFile() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  count=1
  Logger debug "initial: $count"
  for dir in $1/*/;
  do
    dirName=$(echo $dir | sed 's/.*\([0-9]\)\/$/\1/')
    Logger debug "dir: $count - $dir | $dirName"
    if [ "$dirName" != "$dir" ]
    then
      let "count+=1"
      Logger debug "increment: $count - $dir"
    fi
  done
  if [ ! -z "$2" ]
  then
    let "count-=1"
  fi
  echo $count
}
datePath=
setDatePath() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  datePathFile=${rootDir}datePath.txt
  if [ ! -z "$stampName" ]
  then
    datePath=$(cat $datePathFile)
  else
    datePath=`date +%Y/%m/%d`
    echo $datePath > $datePathFile
  fi
}

save() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  definitSize $detailSize $detailSize "$stampName"
  detail=$(definitSize $detailSize $detailSize "$stampName")
  echo -e "$relTime - $detail |$(date)" >> $timeStampFile
}

init() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  mkdir -p $timeStampDir
  touch $timeStampFile
}

calcRelitiveTime() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  local startTimeStr=$(head -1 "$timeStampFile" 2>/dev/null  | sed 's/.*|\(.*\)/\1/')
  local startTime=$(date +%s -d "$startTimeStr")
  local currTime=$(date +%s)
  let "relSec=$currTime - $startTime"
  relTime=$(convertToRelTime $relSec)
}

echo -n "Enter time stamp name: "
read stampName

if [ -z "$stampName" ]
then
  stampName="$@"
fi
setDatePath

targetDir=$rootDir$datePath
mkdir -p $targetDir

timeStampDir="$targetDir/$(findTimeStampFile "$targetDir" "$stampName")"
timeStampFile=$timeStampDir/timeStamps.txt

calcRelitiveTime

if [ -z "$stampName" ]
then
  init
  guvcview --video_timer=999999999 --video=$timeStampDir/webcam.mkv &
  simplescreenrecorder --input_profile=AllScreens --output_profile=mp4 --output_file=$timeStampDir/screenrec.mp4 --record_on_start &
  xdg-open $timeStampDir &
  stampName='Start Time'
  save
elif [ "open" == "$stampName" ]
then
  xdg-open $timeStampDir &
else
  save
fi

mc run vidTimeStamp 'exit'
mc kill vidTimeStamp
