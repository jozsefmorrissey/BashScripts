#!/usr/bin/env bash
mcRelDir=$(dirname "${BASH_SOURCE[0]}")
source ${mcRelDir}/debugLogger.sh;

mcDataDir=~./.opsc/mc
mkdir -p $mcDataDir
propFile="${mcDataDir}/processes.properties"
internalPrefix="internalProp._"
if [ -z "${flags[name]}" ]
then
  echo "-name Must be defined"
  exit
fi

save() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  ${mcRelDir}/properties.sh update "$propFile" "${flags[name]}" "$1" -d ${flags[d]}
}

getValue() {
  debug trace
  ${mcRelDir}/properties.sh value "${flags[name]}" "$propFile" -d ${flags[d]}
}

pidReg='^[0-9]{1,}$'
run() {
  debug trace "$(sepArguments "Argurments: " ", " "$@")"
  id=$(getValue)
  echo id: $id
  if [[ $id =~ $pidReg ]]
  then
    runWithPid $id
  else
    char=${id:0:1}
    id=${id:1}
    if [ "${char}" == "t" ]
    then
      runWithTargetTerm $id "$@"
    fi
  fi


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

reset() {
  save count "1" internal

}

init() {
  debug trace
  if [ "${booleans[t]}" == "true" ]
  then
    target_term add 1
    count=$(target_term count)
    echo $count
    save t$count
  fi
}

watch() {
  debug trace
}

kill() {
  debug trace
  $(getProcess ${flags[name]})
  kill $pid
}

template() {
  debug trace
}

restart() {
  debug trace
}

getValue stuff "things there"
run "$@"
