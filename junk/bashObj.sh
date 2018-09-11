objs=()
types=()
funcs=()

_getObjNames() {
  declare -i stackIndex=$1;
  objName="$2"
  names=()
  while [ "${FUNCNAME[stackIndex]}" != "main" ] && [[ stackIndex -le 10 ]]
  do
    objName+=_${FUNCNAME[stackIndex]}
    names+=" $objName";
    let "stackIndex += 1"
  done
  echo $names;
}

getObjNames() {
  _getObjNames 2
}

getObj() {
  src commandParser.sh
  name=$(setFlag name n)

}

setObj() {
  src commandParser.sh


}

addType() {
  echo t:
  getObjNames
}

getObj() {



  echo $type
}

new() {
  type=$1
  typeIndex=$(getIndex $type $types)
  if [ $typeIndex == -1 ]
  then
    echo null
    return
  fi
  names=($(_getObjNames 2 $2 | tr ' ' "\n"))
  name=${names[-1]}
  echo $names
  echo $name
}

  # Retrieves the index of a string
  #   @$1 - Target String
  #   @$2... - Array to seach
  #   @echo - index of string or -1 if not found
getIndex() {
  count=0
  ret=-1
  target=$1
  shift
  while [ $1 ]
  do
    if [ "$target" == "$1" ]
    then
      ret=$count
    fi
    let "count += 1"
    shift
  done
  echo $ret
}

calling() {
  call() {
    new array philip

  }
  call
}
calling
