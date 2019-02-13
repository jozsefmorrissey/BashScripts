#!/usr/bin/env bash
mcRelDir=$(dirname "${BASH_SOURCE[0]}")
mcRelDir=$(realpath $mcRelDir)
source ${mcRelDir}/debugLogger.sh;

mcDataDir=~/.opsc/mc
mkdir -p $mcDataDir/logs
internalPrefix="internalProp._"
cmdSep="_|_"

processFile="processes.properties"
dirFile="directories.properties"
templateFile="templates.properties"
originDirFile="origin.properties"
pidFile="pid.properties"

if [ -z "${flags[name]}" ] && [ "$1" != "install" ] && [ "$1" != "templates" ]
then
  echo "-name Must be defined"
  exit
fi

splitStringDelimiter() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  str="$1"
  delimiter=$2
  s=$str$delimiter
  array=();
  while [[ $s ]]; do
      array+=( "${s%%"$delimiter"*}" );
      s=${s#*"$delimiter"};
  done;
  declare -p array
}

save() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  ${mcRelDir}/properties.sh update "$mcDataDir/$2" "${flags[name]}" "$1" -d ${flags[d]}
}

getPids() {
  pidStr=$(getValue "$pidFile")
  if [ -z "$pidStr" ]
  then
    array=()
  else
    splitStringDelimiter $pidStr ","
  fi
}

clearPids() {
  save "" "$pidFile"
}

appendPid() {
  getPids
  pids=$(printf "%s," "${array[@]}")
  pids+=$1
  save "$pids" "$pidFile"
}

getLog() {
  echo $mcDataDir/logs/${flags[name]}.log
}

getDirectory() {
  getValue $dirFile
}

getValue() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  ${mcRelDir}/properties.sh value "${flags[name]}" "$mcDataDir/$1" -d ${flags[d]}
}

runWithPid() {
  debug trace
  kill -0 $pid
}

runWithTargetTerm() {
  id=$1
  shift
  target_term run $id "$@"
}

init() {
  debug trace
  if [ "${booleans[t]}" == "true" ]
  then
    target_term add 1
    count=$(target_term count)
    echo $count
    save $count $processFile
  else
    echo bash cmd
  fi
}

# ----------------------------- Command functions ------------------------------
pidReg='^[0-9]{1,}$'
run() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  id=$(getValue $processFile)
  echo id: $id
  if [[ $id =~ $pidReg ]]
  then
    runWithTargetTerm $id "$@"
  else
    echo "$(getDirectory)> $@" &>> $(getLog)
    ogDir=$(pwd)
    cd "$(getDirectory)"
    $@ &>> "$(getLog)" &
    cd "$ogDir"
    pid=$!
    debug debug "Process Name: ${flags[name]} PID:$pid"
    appendPid $pid
  fi
}

watch() {
  debug trace
  less +F "$(getLog)"
}

KILL() {
  debug trace
  getPids
  for pid in ${array[@]}
  do
    echo $pid
    kill $pid
  done
  clearPids
}

template() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  save "$(realpath "${flags[od]}")" "$originDirFile"
  save "$(sepArguments "" "$cmdSep" "$@")" "$templateFile"
}

restart() {
  debug trace
  kill
  start
}

start() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  string=$(getValue $templateFile)
  splitStringDelimiter "$string" "$cmdSep"
  od=$(getValue $originDirFile)
  CD "$od"
  for i in "${!array[@]}"
  do
      run "${array[i]}"
  done
}

clear() {
  echo "" &> $(getLog)
}

CD() {
  debug debug "$(sepArguments "Argurments: " ", " "$@")"
  currDir=$(getDirectory)
  debug debug "curr: \"$currDir\""
  if [ "${1:0:1}" == "~" ]
  then
    newDir=$(realpath "$HOME/${1:1}")
  elif [ "${1:0:1}" == "/" ] || [ -z "$currDir" ]
  then
    newDir=$(realpath $1)
  else
    newDir=$(realpath $currDir/$1)
  fi
  if [ -d "$newDir" ]
  then
    debug debug "New Dir: $newDir"
    save "$newDir" "$dirFile"
  else
    debug debug "Not a Directory $newDir"
  fi
}

install() {
  echo "bash $mcRelDir/mc.sh \"\$@\"" > /usr/bin/mc
}

LS() {
  directory=$(getDirectory)/$1
  echo $(realpath $directory)"> ls"
  ls -${flags[flags]} $directory
}

templates() {
  ${mcRelDir}/properties.sh each "$mcDataDir/$templateFile" 'echo k:' -d ${flags[d]}
}

cmd=$1
shift
if [ "$cmd" == "cd" ] || [ "$cmd" == "kill" ] || [ "$cmd" == "ls" ]
then
  cmd=$(echo "$cmd" | tr a-z A-Z)
fi
$cmd "$@"
