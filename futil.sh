REP_PREFIX='${'
REP_SUFFIX='}'
FUTIL_REL_DIR=$(dirname "${BASH_SOURCE[0]}")
source $FUTIL_REL_DIR/commandParser.sh

replace() (
  source $FUTIL_REL_DIR/commandParser.sh -scope ${FUNCNAME[0]} "$@"
  echo ${replaceFlags[f]}
  [ $# -ge 1 -a -f "$2" ] && input="$2" || input="-"
  if [ -n "${replaceFlags[prefix]}" ] || [ -n "${replaceFlags[suffix]}" ]
  then
    REP_PREFIX="${replaceFlags[prefix]}"
    REP_SUFFIX="${replaceFlags[suffix]}"
  fi
  contents=$(cat $input)
  keys=($(eval echo "\${!${replaceFlags[array]}[@]}"))
  for i in "${keys[@]}"
  do
    key=$i
    value=$(eval echo "\${${replaceFlags[array]}[$key]}")
    contents=$(echo -e "$contents" | sed "s|$REP_PREFIX$key$REP_SUFFIX|$value|g")
  done
  echo -e "$contents"
)

# declare -A array
# array[hello]=greetings
# array[place]=earth
#
# echo cmd: ${flags[cmd]}
#
# echo $(flagStr)
#
# echo -e "\${hello}\n\${place}\n" | replace -array array
# echo $(flagStr)
