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

name=$1
shift

if [ -z "$name" ] && [ "$1" != "install" ] && [ "$1" != "templates" ] && [ "$1" != "reset"]
then
  echo "-name Must be defined"
  exit
fi

list_descendants ()
{
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    list_descendants "$pid"
  done

  echo "$children"
}

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
  ${mcRelDir}/properties.sh update "$mcDataDir/$2" "$name" "$1" -d ${flags[d]}
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
  debug trace
  save "" "$pidFile"
}

appendPid() {
  getPids
  pids=$(printf "%s," "${array[@]}")
  pids+=$1
  save "$pids" "$pidFile"
}

getLog() {
  echo $mcDataDir/logs/$name.log
}

getDirectory() {
  getValue $dirFile
}

getValue() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  ${mcRelDir}/properties.sh value "$mcDataDir/$1" "$name" -d ${flags[d]}
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

killTargetTerm() {
  debug trace
  termId=$(getValue $processFile)
  debug debug termId: $termId
  if [ ! -z "$termId" ]
  then
    debug debug "TermID: $termId"
    target_term kill $termId
    save "" $processFile
  fi
}

init() {
  debug trace
  termId=$(getValue $processFile)
  if [ "${booleans[t]}" == "true" ] && [ -z "$termId" ]
  then
    target_term add 1
    termId=$(target_term count)
    save $termId $processFile
  fi
}

# ----------------------------- Command functions ------------------------------
pidReg='^[0-9]{1,}$'
run() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  init
  if [ ! -z "$termId" ]
  then
    echo termId: $termId
    cd=$(getDirectory)
    runWithTargetTerm $termId "cd $cd"
    echo runWithTargetTerm $termId "$@"
    runWithTargetTerm $termId "$@"
  else
    echo "$(getDirectory)> $@" &>> $(getLog)
    ogDir=$(pwd)
    cd "$(getDirectory)"
    $@ &>> "$(getLog)" &
    cd "$ogDir"
    pid=$!
    debug debug "Process Name: $name PID:$pid"
    appendPid $pid
  fi
}

watch() {
  debug trace
  less +F "$(getLog)"
}

KILL() {
  debug trace
  killTargetTerm
  getPids
  for pid in ${array[@]}
  do
    echo $pid
    kill $(list_descendants $pid)
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
  KILL
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
  debug trace
  echo "" &> $(getLog)
}

reset() {
  debug trace
  echo "$mcDataDir/$processFile"
  echo "" &> "$mcDataDir/$processFile"
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

if [ -z "$1" ]
then
  $name
else
  while [ ! -z "$1" ]
  do
    cmd=$1
    shift
    if [ "$cmd" == "cd" ] || [ "$cmd" == "kill" ] || [ "$cmd" == "ls" ]
    then
      cmd=$(echo "$cmd" | tr a-z A-Z)
    fi
    $cmd "$@"
  done
fi
