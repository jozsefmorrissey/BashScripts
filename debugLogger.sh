
DEBUG_REL_DIR=$(dirname "${BASH_SOURCE[0]}")
source $DEBUG_REL_DIR/commandParser.sh

debugLevelId=${flags['d']}

if [ -z $debugLevelId ]
then
  debugLevelId="fatal"
else
  debugLevelId=$(echo "$debugLevelId" | tr '[:upper:]' '[:lower:]')
fi


declare -A loggingLevels
loggingLevels["off"]=0
loggingLevels["fatal"]=1
loggingLevels["error"]=2
loggingLevels["warn"]=3
loggingLevels["info"]=4
loggingLevels["debug"]=5
loggingLevels["trace"]=6
loggingLevels["all"]=7

debugLevel=${loggingLevels["$debugLevelId"]}

Logger () {
  levelId=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  level=${loggingLevels["$levelId"]}
  if [ ! -z $level ] && [ ! -z $debugLevel ] && [ $level -le $debugLevel ]
  then
    callerInfo=$(caller 0)
    (>&2 echo -e "[$levelId] $callerInfo - $2")
  fi
}

sepArguments() {
  argStr="$1"
  seperator="$2"
  shift
  shift
  for arg in "$@"
  do
    argStr+="${arg}$seperator"
  done
  end=${#seperator}
  let "end*=-1"
  echo ${argStr:0:$end}
}
