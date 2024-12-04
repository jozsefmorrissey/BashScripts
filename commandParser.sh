
if [ "$1" == '-scope' ]
then
  flagArrayName=$2Flags
  booleanArrayName=$2Booleans
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
      if [ "${arg:1:1}" != "-" ] && ( [ -z "$1"  ] || [ "${rev:0:1}" == ":" ] )
      then
        bool=$(echo ${arg:1} | sed s/://g)
        eval $booleanArrayName[\$bool]=true
      else
        value=$1
        eval $flagArrayName[\${arg:2}]=\$value
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
      str+="--$i $(eval echo \${$flagArrayName[$i]}) "
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

if [ scoped ]
then
  eval declare -A 'arguments'
  arguments=${args[@]};
else
  set -- "${@:1:}" "${args[@]}"
fi
