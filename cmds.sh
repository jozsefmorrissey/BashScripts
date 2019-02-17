#!/bin/bash

# All functions will deal with the same following properties
#   @$1 - String Id
#   @$2 - Property Key

getFileName () {
  echo ./$1/cmds.properties
}

#
# getValue
#   @$1 - property name
#   @$2 - filePath
#
getValue() {
  filePath=$(getFileName $1)
  properties.sh value $1 $2
}

viewFile() {
  filePath=$(getFileName $1)
  gedit $filePath
}

#
# getValue
#   @$1 - property name
#   @$2 - property value
#   @$3 - filePath
#
update () {
  filePath=$(getFileName $1)
  properties.sh update "$filePath" "$2" "$3"
}

# These are the comments
# That never end
# It goes on and on my friends
case "$1" in
  edit)
    viewFile "$2"
  ;;
  list)
    filePath=$(getFileName $2)
    cat "$filePath"
  ;;
  value)
    getValue "$2" "$3"
  ;;
  update)
    update "$2" "$3" "$4"
  ;;
esac
