#!/usr/bin/env bash

FILE_CODE_REL_DIR=$(dirname "${BASH_SOURCE[0]}")
source $FILE_CODE_REL_DIR/commandParser.sh

FC_HOME=~/.opsc/fileCode/
defaultCipher=./cipher.txt

getCipher() {
  if [ ! -z ${flags['cipher']} ]
  then
    echo ${flags['cipher']}
  else
    echo $defaultCipher
  fi
}

setup() {
  cipher=$(getCipher)
  fileSize=0$(stat -c%s "$cipher" 2>/dev/null)
  echo fileSize: $fileSize
  while [ "$fileSize" -lt "50000" ]
  do
    babelUrl=https://libraryofbabel.info/download.cgi
    RANDOM=$$
    hex=$(find . -type f | shuf -n 1 | md5sum | sed "s/\(.\{6\}\).*/\1/")
    let "wall=$RANDOM % 4 + 1"
    let "shelf=$RANDOM % 5 + 1"
    let "volume=$RANDOM % 32 + 1"
    data="hex=$hex&wall=$wall&shelf=$shelf&volume=$volume&title=cipher"
    echo $data
    curl --data $data $babelUrl > $cipher
    fileSize=0$(stat -c%s "$cipher" 2>/dev/null)
    echo fileSize: $fileSize
  done
}

generate() {
  cipher=$(getCipher)
  string=$(sed "s/\s*//g" ${cipher} | tr -d "\n")
  hashedKey=$(echo "${flags['key']}" | md5sum | sed "s/\(.*\)\? .*/\1/")
  code=""
  index=0

  location=${hashedKey:index:1}
  code+=${string:location:1}

  while [ "$index" -lt "${#hashedKey}" ]
  do
    let "value=${hashedKey:index:1}" 2>/dev/null
    if [ $value -ne 0 ]
    then
      let "location*=$value" 2>/dev/null
      let "location+=$value" 2>/dev/null
    else
      let "location*=2"
    fi
    let "curr=${location}"
    let "curr%=${#string}"
    let "index+=1"
    code+="${string:curr:1}"
  done

  echo $code
}

if [ "${args[0]}" == "setup" ]
then
  setup
else
  generate
fi
