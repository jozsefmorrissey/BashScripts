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

#
# each
# itterates over all arguments
#   @$1 - command to run for each k: will be replaced by key, v: will be replaced by the keys value
#   @$2 - filePath
#
each () {
  dirtyKeys=$(grep -oP "^[^\#]*=.*" $1 )
  for dirtyKey in ${dirtyKeys//\\n/}
  do
    key=$(echo $dirtyKey | sed "s/\s*\([^=]*\)=\(.*\)/\1/")
    key=$(echo $key | sed "s/\./ /g")
    value=$(echo $dirtyKey | sed "s/\s*\(.*\)=\(.*\)/\2/")
    if [[ $value =~ ^\#\#REQUEST\#\#\s*$ ]]
    then
      read -p "Enter '$key' for your system: " userInput
      value=$userInput
    fi
    cmd=$(echo $2 | sed "s/k:/$key/g")
    cmd=$(echo $cmd | sed "s/v:/$value/g")
    $cmd
  done
}

# These are the comments
# That never end
# It goes on and on my friends
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
