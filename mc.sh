#!/usr/bin/env bash
mcRelDir=$(dirname "${BASH_SOURCE[0]}")
mcRelDir=$(realpath $mcRelDir)
source ${mcRelDir}/debugLogger.sh;

echo $1

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

exitCmd=

if [ -z "$name" ] && [ "$cmd" == "run" ]
then
  name=$(pwgen 30 1)
  exitCmd=' && exit'
fi

if [ -z "$name" ] && [ "$cmd" != "run" ] && [ "$cmd" != "install" ] && [ "$cmd" != "templates" ] && [ "$cmd" != "reset"]
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

cleanPids() {
  getPids
  clearPids
  for pid in ${pidArray[@]}
  do
    if kill -0 $pid > /dev/null 2>&1; then
      appendPid $pid
    fi
  done
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
  Logger debug "$@"
  target_term.py run $id "$@"
}

killTargetTerm() {
  Logger trace
  termId=$(getValue $processFile)
  Logger debug termId: $termId
  if [ ! -z "$termId" ]
  then
    Logger debug "TermID: $termId"
    target_term.py kill $termId
    save "" $processFile
  fi
}

init() {
  Logger trace
  termId=$(getValue $processFile)
  if [ "${booleans[t]}" == "true" ] && [ -z "$termId" ]
  then
    target_term.py add 1
    termId=$(target_term.py count)
    save $termId $processFile
  fi
}

# ----------------------------- Command functions ------------------------------
help() {
  echo 'Run commands in a named shell use -t at end, or -t: anywhere to open a terminal.'
  echo -e "mc run \$NAME [COMMANDS]\n\truns the given commands in the named window"
  echo -e "mc run \"\" [COMMANDS]\n\truns the given commands in an anonymous window"
  echo -e "mc watch \$NAME\n\topens a output watcher for the given window"
  echo -e "mc kill \$NAME\n\tkills all the processes connected to the given id"
  echo -e "mc start \$NAME\n\treruns template commands"
  echo -e "mc restart \$NAME\n\tkills & starts"
  echo -e "mc reset \$NAME\n\t removes processes associations without killing"
  echo -e "mc clear \$NAME\n\tclears the log"
  echo -e "mc ls \$NAME\n\truns ls and prints output to current window"
  echo -e "mc cd \$NAME\n\truns cd in target window"
  echo -e "mc templates\n\tprints templates"
  echo -e "mc template -od \$OriginDirectory \$NAME [COMMANDS]\n\tcreates a template"
  echo -e "mc install\n\tinstalls on and initializes your computer"
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
    Logger debug runWithTargetTerm $termId "$@$exitCmd"
    runWithTargetTerm $termId "$@$exitCmd"
  else
    echo "$(getDirectory)> $@" &>> $(getLog)
    ogDir=$(pwd)
    cd "$(getDirectory)"
    Logger info "Exicute Cmd: $@ &"
    eval "$@$exitCmd &>> \"$(getLog)\" &"
    cd "$ogDir"
    pid=$!
    Logger debug "Process Name: $name PID:$pid"
    cleanPids
    appendPid $pid
  fi
}

watch() {
  Logger trace
  less +F "$(getLog)"
}

KILL() {
  Logger trace
  cleanPids
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
  echo "$mcRelDir/target_term.py \"\$@\"" > /usr/bin/target_term.py
  sudo chmod +x /usr/bin/target_term.py
  mkdir -p ${mcDataDir}
  touch $mcDataDir/$processFile
  touch $mcDataDir/$dirFile
  touch $mcDataDir/$templateFile
  touch $mcDataDir/$originDirFile
  touch $mcDataDir/$pidFile
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
