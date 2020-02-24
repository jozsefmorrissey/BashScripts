#!/usr/bin/env bash

INSTALL_REF_REL_DIR=$(dirname "${BASH_SOURCE[0]}")
source $INSTALL_REF_REL_DIR/commandParser.sh

overwrite() {
  saveRef
  echo
  exit
}

help() {
  echo "Script saves a redirect reference to a script in the following form."
  echo -e "\t[prefix] [script] \"\$@\""
  echo -e "Into either /user/bin or /bin.\t(*=Required)"
  echo -e "\t-cmd* : command to run script"
  echo -e "\t-script* : script location\n"
  echo -e "\t-global : save to /bin"
  echo -e "\t-prefix : Default \"bash\""
}

validateCmd() {
  cmd="${flags[cmd]}"
  while [ ! -z "$(compgen -acbk | grep -oP "^$cmd\$")" ]
  do
    echo "Command \"$cmd\" already taken what would you like to do?"
    echo -e "\tExit - ctrl+c"
    echo -e "\tSave Anyway - ctrl+z"
    echo -e -n "\tTry new name: "
    read cmd
    echo
    binPath=/bin/$cmd
  done
}

saveRef() {
  echo "$prefix ${script} \"\$@\"" > "$binPrefix$binPath"
  chmod +x "$binPrefix$binPath"
}

process() {
  script=$(readlink -f ${flags[script]})

  prefix=${flags[prefix]}

  if [ -z "$prefix" ]
  then
    prefix=bash
  fi

  binPrefix='/usr'
  if [ ${booleans[global]} ]
  then
    binPrefix=
  fi

  binPath=/bin/${flags[cmd]}
  validateCmd
  saveRef
}

trap overwrite SIGTSTP

if [ ${booleans[help]} ] || [ -z "${flags[script]}" ] || [ -z "${flags[cmd]}" ]
then
  help
else
  process
fi
