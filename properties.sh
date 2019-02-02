#!/bin/bash

# All functions will deal with the same following properties
#   @$1 - String Id
#   @$2 - Property Key

#
# getValue
#   @$1 - property name
#   @$2 - filePath
#
getValue() {
  value=$(grep -oP "$1=.*" $2 | sed "s/.*=//g")
  echo $1 $2
  if [ ! -z "$value" ]
  then
    echo $value
  fi
}

viewFile() {
  gedit $1
}

#
# getValue
#   @$2 - property name
#   @$3 - property value
#   @$1 - filePath
#
update () {
  old=$(getValue "$2" "$1")
  echo old "$old"
  sed -i "s/$2=.*//g" $1
  echo "$2=$3" >> "$1"
}

cleanSedReg() {
  echo "$1" | sed -e 's/[\/&]/\\&/g'
}

cleanKey() {
  echo $1 | sed "s/\./_/g"
}

refReg="\${\(.*\)\?}"
refReplaceReg() {
  echo "^\(.*[^\\]\|\)$1\(.*\)$"
}

refIsolateReg=$(refReplaceReg "$refReg")
hasRef() {
  ref=$(echo "$1" | sed "s/$refIsolateReg//g")
  [ "$ref" == "" ] && echo true
}

removeRefs() {
  val=$1
  while [[ "true" == "$(hasRef $val)" ]]
  do
    k=$(echo "$val" | sed "s/$refIsolateReg/\2/g")
    kId=$(cleanKey "$k")
    refRepReg=$(refReplaceReg "\${\\($k\\)}")
    refval=$(cleanSedReg "${props[$kId]}")
    val=$(echo "$val" | sed "s/$refRepReg/\1$refval\3/g")
  done
  echo $val
}

#
# each
# itterates over all arguments
#   @$1 - command to run for each k: will be replaced by key, v: will be replaced by the keys value
#   @$2 - filePath
#
declare -A props
each () {
  lines=$(grep -oP "^[^\#]*=.*" $1 )
  for line in ${lines//\\n/}
  do
    line=$(cleanSedReg $line)
    rawKey=$(echo "$line" | sed "s/\(.*\?\)=.*/\1/g")

    identifier=$(echo "$rawKey" | sed "s/\./ /g")
    key=$(cleanKey "$rawKey")

    value=$(echo $line | sed "s/\s*\(.*\)=\(.*\)/\2/")
    value=$(removeRefs "$value")
    echo $key=$value -$identifier : $line : $rawKey
    props[$key]=$value
    if [[ $value =~ ^\#\#REQUEST\#\#\s*$ ]]
    then
      read -p "Enter '$identifier' for your system: " userInput
      value=$userInput
      if [ -z $value ]
      then
        continue
      elif [ "$value" == "?" ]
      then
        value=
      fi
    fi
    cmd=$(echo $2 | sed "s/k:/$identifier/g")
    cmd=$(echo $cmd | sed "s/v:/$value/g")
    $cmd
    echo $cmd
    echo
  done
}

#
# These are the comments
# That never end
# It goes on and on my friends
#
case "$1" in
  edit)
    viewFile "$2"
  ;;
  list)
    cat "$2"
  ;;
  value)
    getValue "$2" "$3"
  ;;
  update)
    update "$2" "$3" "$4"
  ;;
  each)
    each "$2" "$3"
  ;;
esac
