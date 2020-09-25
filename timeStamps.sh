#!/bin/bash

timeStampRelDir=$(dirname "${BASH_SOURCE[0]}")
timeStampRelDir=$(realpath $timeStampRelDir)
source ${timeStampRelDir}/debugLogger.sh;

rootDir=/home/$USER/Videos/
datePathFile=${rootDir}datePath.txt
detailSize=32
timeSize=8
topic=

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

datePath=
getDatePath() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  datePath=$(cat $datePathFile)
}

save() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  definitSize $detailSize $detailSize "$stampName"
  detail=$(definitSize $detailSize $detailSize "$stampName")
  echo -e "$relTime - $detail |$(date)" >> $timeStampFile
}

init() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  mkdir -p $targetDir
  touch $timeStampFile
}

calcRelitiveTime() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  local startTimeStr=$(head -1 "$timeStampFile" 2>/dev/null  | sed 's/.*|\(.*\)/\1/')
  if [ -z "$startTimeStr" ]
  then
    relTime='00:00:00'
  else
    local startTime=$(date +%s -d "$startTimeStr")
    local currTime=$(date +%s)
    let "relSec=$currTime - $startTime"
    relTime=$(convertToRelTime $relSec)
  fi
}

determinePath() {
  getDatePath

  targetDir=$rootDir$datePath
  mkdir -p $targetDir

  timeStampFile=${targetDir}/timeStamps.txt
  calcRelitiveTime
}

startRecording() {
  echo -n "Enter topic name: "
  read topic
  echo "'$topic'"
  datePath=`date +%Y/%m/%d`"/$topic"
  echo $datePath > $datePathFile
  echo -e "\n\n$topic\n\n"
  determinePath
  init
  guvcview --video_timer=999999999 --video=$targetDir/webcam.mkv --audio_device=2 &
  # simplescreenrecorder --start-recordin &
  echo "simplescreenrecorder --input_profile=AllScreens --output_profile=mp4 --output_file=$targetDir/screenrec.mp4 --record_on_start &"
  simplescreenrecorder --input_profile=AllScreens --output_profile=mp4 --output_file=$targetDir/screenrec.mp4 --record_on_start &
  xdg-open $targetDir &
  stampName='Start Time'
  save
}

openFileSystem () {
  determinePath
  xdg-open $targetDir &
}

saveTimeStamp () {
  if [ -z "$stampName" ]
  then
    stampName="$@"
  fi

  determinePath
  save
}


if [ -z "$(pgrep guvcview)" ]
then
  startRecording
else
  echo -n "Enter time stamp name (open to open Directory): "
  read stampName
  if [ "open" == "$stampName" ]
  then
    echo openning
    openFileSystem
  else
    saveTimeStamp
  fi
fi
