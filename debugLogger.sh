
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

debug () {
  levelId=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  level=${loggingLevels["$levelId"]}
  if [ $level -le $debugLevel ]
  then
    callerInfo=$(caller 0)
    (>&2 echo "[$levelId] $callerInfo - $2")
  fi
}
