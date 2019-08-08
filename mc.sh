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

cmd=$1
shift
name=$1
shift

echo Name: $name

if [ -z "$name" ] && [ "$cmd" != "install" ] && [ "$cmd" != "templates" ] && [ "$cmd" != "reset"]
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
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  str="$1"
  delimiter=$2
  s=$str$delimiter
  eval "$3=()"
  Logger debug "Array name: $3"
  while [[ $s ]]; do
      eval "$3+=( \"${s%%"$delimiter"*}\" );"
      s=${s#*"$delimiter"};
  done;
}

save() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  ${mcRelDir}/properties.sh update "$mcDataDir/$2" "$name" "$1" -d ${flags[d]}
}

getPids() {
  pidStr=$(getValue "$pidFile")
  if [ -z "$pidStr" ]
  then
    pidArray=()
  else
    splitStringDelimiter $pidStr "," "pidArray"
  fi
}

clearPids() {
  Logger trace
  save "" "$pidFile"
}

appendPid() {
  getPids
  pids=$(printf "%s," "${pidArray[@]}")
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
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  ${mcRelDir}/properties.sh value "$mcDataDir/$1" "$name" -d ${flags[d]}
}

runWithTargetTerm() {
  id=$1
  shift
  target_term run $id "$@"
}

killTargetTerm() {
  Logger trace
  termId=$(getValue $processFile)
  Logger debug termId: $termId
  if [ ! -z "$termId" ]
  then
    Logger debug "TermID: $termId"
    target_term kill $termId
    save "" $processFile
  fi
}

init() {
  Logger trace
  termId=$(getValue $processFile)
  if [ "${booleans[t]}" == "true" ] && [ -z "$termId" ]
  then
    target_term add 1
    termId=$(target_term count)
    save $termId $processFile
  fi
}

# ----------------------------- Command functions ------------------------------
help() {
  echo 'Run commands in a named shell use -t at end, or -t: anywhere to open a terminal.'
  echo 'mc run $NAME [COMMANDS]'
  echo 'mc watch $NAME'
  echo 'mc kill $NAME'
  echo 'mc restart $NAME'
  echo 'mc start $NAME'
  echo 'mc clear $NAME'
  echo 'mc reset $NAME'
  echo 'mc ls $NAME'
  echo 'mc cd $NAME'
  echo 'mc templates'
  echo 'mc template -od $OriginDirectory $NAME [COMMANDS]'
  echo 'mc install'
}

pidReg='^[0-9]{1,}$'
run() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  init
  Logger debug "TermID: $termId"
  if [ ! -z "$termId" ]
  then
    cd=$(getDirectory)
    runWithTargetTerm $termId "cd $cd"
    Logger debug runWithTargetTerm $termId "$@"
    runWithTargetTerm $termId "$@"
  else
    echo "$(getDirectory)> $@" &>> $(getLog)
    ogDir=$(pwd)
    cd "$(getDirectory)"
    Logger info "Exicute Cmd: $@ &"
    eval "$@ &>> \"$(getLog)\" &"
    cd "$ogDir"
    pid=$!
    Logger debug "Process Name: $name PID:$pid"
    appendPid $pid
  fi
}

watch() {
  Logger trace
  less +F "$(getLog)"
}

KILL() {
  Logger trace
  killTargetTerm
  getPids
  for pid in ${pidArray[@]}
  do
    Logger info "kill -9 $(list_descendants $pid) $pid"
    kill -9 $(list_descendants $pid) $pid
  done
  clearPids
}

template() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  save "$(realpath "${flags[od]}")" "$originDirFile"
  save "$(sepArguments "" "$cmdSep" "$@")" "$templateFile"
}

restart() {
  Logger trace
  KILL
  start
}

start() {
  Logger trace "$(sepArguments "Argurments: " ", " "$@")"
  string=$(getValue $templateFile)
  splitStringDelimiter "$string" "$cmdSep" "cmds"
  od=$(getValue $originDirFile)
  CD "$od"
  for i in "${!cmds[@]}"
  do
    Logger debug "Command Loop: ${cmds[i]}"
    run "${cmds[i]}"
  done
}

clear() {
  Logger trace
  echo "" &> $(getLog)
}

reset() {
  Logger trace
  echo "$mcDataDir/$processFile"
  echo "" &> "$mcDataDir/$processFile"
}


CD() {
  Logger debug "$(sepArguments "Argurments: " ", " "$@")"
  currDir=$(getDirectory)
  Logger debug "curr: \"$currDir\""
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
    Logger debug "New Dir: $newDir"
    save "$newDir" "$dirFile"
  else
    Logger debug "Not a Directory $newDir"
  fi
}

install() {
  echo "bash $mcRelDir/mc.sh \"\$@\"" > /usr/bin/mc
  sudo chmod +x /usr/bin/mc
  mkdir -p ${mcDataDir}
  touch ${mcDataDir}/processes.properties ${mcDataDir}/directories.properties
}

LS() {
  directory=$(getDirectory)/$1
  echo $(realpath $directory)"> ls"
  ls -${flags[flags]} $directory
}

templates() {
  # ${mcRelDir}/properties.sh each 'echo -e k:\n' "$mcDataDir/$templateFile" -d ${flags[d]}
  cat "$mcDataDir/$templateFile"
}

if [ -z "$cmd" ]
then
  help
else
  if [ "$cmd" == "cd" ] || [ "$cmd" == "kill" ] || [ "$cmd" == "ls" ]
  then
    cmd=$(echo "$cmd" | tr a-z A-Z)
  fi
  $cmd "$@"
fi
