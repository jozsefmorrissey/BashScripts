#!/bin/bash

source ./commentConfig.sh
source ./commandParser.sh

startReg=$(setFlag startReg s)
echo startReg: $startReg
endReg=$(setFlag endReg e)
echo endReg: $endReg
nameReg=$(setFlag nameReg n)
echo nameReg: $nameReg
argReg=$(setFlag argReg a)
echo argReg: $argReg
argDefSep=$(setFlag argDefSep as)
echo argDefSep: $argDefSep
argDescReg=$(setFlag argDescReg ad)
echo argDescReg: $argDescReg
argSecReg=''
argNameReg=''
argDefReg=''

getPartial() {
  regex="^.*?\s$1.*"
  # echo "$regex=>$2"
  if [[ $2 =~ $regex ]];
  then
    echo INfunc ${BASH_REMATCH[1]}
  fi
}

buildArgReg () {
  argSecReg=$argReg$argDefSep$argDescReg
  argNameReg=$argReg$argDefSep
  argDefReg=$argDefSep$argDescReg
}

getArgs () {
  argLines=$(echo "$1" | sed -r "s/($argNameReg)/\r\n\1/g")
  echo "$argLines" | grep -oP "$argSecReg" | while read arg
  do
    echo loop: "$arg"
    getPartial "$argNameReg" " $arg"
    getPartial "$argDefReg" " $arg"
  done
}

grepSep="~"
#\r\n!-!-!-!-!-!-^-^-^-^-^-^-^-^-^-^-^-!-!-!-!-!-!\r\n



getComments () {
  commentReg="$startReg(\s*[^'])*$endReg\s*$nameReg"
  echo $(grep -zoPH  "$commentReg" ./confidentalInfo.sh)$grepSep |
    sed "s/\.\/confidentalInfo\.sh:/$grepSep/g" |
    while read -d "$grepSep" comment
      do
        echo New Comment!!!!!!!!!!!!!!!!
        echo nulls: "$comment"
        noNewNuls=$(echo $comment)
        getArgs "$comment"
        getPartial "$nameReg" "$noNewNuls"
      done
}

buildArgReg
file=${args[0]}
getComments
# getComments
# comment=$(grep -zoP "$startReg(\s*[^'])*$endReg\s*$nameReg" ./confidentalInfo.sh)
# echo "$comment"
# echo "$comment" | grep -zoP "$nameReg"

# echo "$nameReg" | grep -zoP "nameRe"
# noNewNuls=$(echo $comment)
#
# getArgs


# getPartial "$nameReg" "$noNewNuls"
# noNewNuls=$(echo $comment)

# exp=$(echo "$argsss" | tr "\n" "%")
# ar=$(readarray -t y <<<"$argsss")#$(echo "$exp" | grep -oP "$argReg" | xargs -d "%")
