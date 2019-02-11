declare -A flags
declare -A booleans
args=()

while [ "$1" ];
do
    arg=$1
    if [ "${1:0:1}" == "-" ]
    then
      shift
      rev=$(echo "$arg" | rev)
      if [ -z "$1" ] || [ "${1:0:1}" == "-" ] || [ "${rev:0:1}" == ":" ]
      then
        bool=$(echo ${arg:1} | sed s/://g)
        booleans[$bool]=true
      else
        value=$1
        flags[${arg:1}]=$value
        shift
      fi
    else
      args+=("$arg")
      shift
    fi
done


# setFlag () {
#   first=$1
#   while [ "$1" ];
#   do
#     if [ ${flags[$1]} ]
#     then
#       echo ${flags[$1]}
#       return
#     fi
#     shift
#   done
#
#   eval "arr=\${$first[$type]}"
#   echo $arr
#   # echo ${defaults[$first]}
# }

set -- "${@:1:}" "${args[@]}"
