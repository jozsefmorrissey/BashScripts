
if [ "$1" == '-scope' ]
then
  flagArrayName="${2}Flags"
  booleanArrayName="${2}Booleans"
  scopedArgName="${2}Args";
  echo "first $scopedArgName"
  eval declare -A $scopedArgName
  shift
  shift
else
  flagArrayName=flags
  booleanArrayName=booleans
fi
eval declare -A $flagArrayName
eval declare -A $booleanArrayName


args=()

currentIndex=0
terminationIndex=$#
while (( currentIndex < terminationIndex ));
do
    let "currentIndex+=1"
    arg=$1
    if [ "${1:0:1}" == "-" ]
    then
      shift
      rev=$(echo "$arg" | rev)
      if [ -z "$1" ] || [ "${1:0:1}" == "-" ] || [ "${rev:0:1}" == ":" ]
      then
        if [ "${arg:1:1}" == '-' ]
        then
          bool=$(echo ${arg:2} | sed s/://g)
          eval $booleanArrayName[\$bool]=true
        else
          str=$(echo "${arg:1}" | sed s/://g)
          for ((i=0; i < ${#str}; i++));
          do
            char=${str:i:1};
            eval $booleanArrayName[\$char]=true
          done
        fi
      else
        value=$1
        eval $flagArrayName[\${arg:1}]=\$value
        shift
      fi
    else
      args+=("$arg")
      shift
    fi
done

flagStr() {
  str=''
  for i in "$(eval echo \${\!$flagArrayName[@]})"
  do
    if [ -n "$i" ]
    then
      str+="-$i $(eval echo \${$flagArrayName[$i]}) "
    fi
  done
  echo $str
}

boolStr() {
  str=''
  for i in "$(eval echo \${\!$booleanArrayName[@]})"
  do
    if [ -n "$i" ]
    then
      str+="-$i "
    fi
  done
  echo $str
}

if [ scopedArgName ]
then
  eval "$scopedArgName=\${args[@]}"
else
  set -- "${@:1:}" "${args[@]}"
fi
