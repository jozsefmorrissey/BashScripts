#!/bin/bash

# All functions will deal with the same following properties
#   @$1 - String Id
#   @$2 - Property Key

password="amu0ohMihohQuoh3AuYo1aihiet9ei"
relDir='/home/jozsef/info/'
tempName="thahb9da7aegahpaic3ohKahchoube"
tempExt='.txt'
encryptExt='.des3'
logId="log-history-unlikely-user-name"

log() {
  halfPart=$(echo -n -e "------------------------- ")
  oHalfPart=$(echo -n -e $halfPart | rev)
  d=$(date +%F_%H-%M-%S)
  lg=$(echo -n -e "\n\n$d\n$halfPart $1:$2:$3 $oHalfPart\n$4")
  appendToFile "$logId" "$lg"
  echo -n
}

getFileName() {
  if [ $1 == 'infoMap' ]
  then
    file='Heena6airooshahze8eeh2fohruu4c';
  else
    file=$(getValue infoMap $1)
  fi

  if [ "$file" ]
  then
    echo $relDir$file
  fi
}

getTempName () {
  echo $(getFileName $1)$tempExt
}

getEncryptName() {
  echo $(getFileName $1)$encryptExt
}

getValue() {
  decoded=$(decode "$1")
  value=$(echo "$decoded" | grep -oP "$2=.*" | sed "s/.*=//g")
  if [ ! -z $value ]
  then
    echo $value
  fi
}

decode() {
  encryptName=$(getEncryptName $1)
  cmd="openssl des3 -d < $encryptName -pass pass:$password"
  # Unlock -> decrypt -> Lock.... TODO: Find a way to simplify this.
  decoded=$(sudo chmod +r $encryptName && openssl des3 -d < $encryptName -pass pass:$password && sudo chmod -r $encryptName)
  echo "$decoded"
}

setupTemp() {
  tempName=$(getTempName $1)
  encryptName=$(getEncryptName $1)
  touch $encryptName
  echo "$(decode $1)" > $tempName
}

mapFile() {
  filename=$(getValue infoMap "$1")
  if [[ -z $filename ]] && [ $1 != "infoMap" ]
  then
    genValue=$(pwgen 30 1)
    filename="$genValue"
    echo filename $filename
    touch $relDir$filename$encryptExt
    appendToFile "infoMap" "$1=$filename"
  fi

  echo $filename
}

#
#stuff
#
#new
#
saveAndRemoveTemp () {
  tempName=$(getTempName $1)
  encryptName=$(getEncryptName $1)
  # Unlock -> encrypt -> Lock.... TODO: Find a way to simplify this.
  sudo chmod +rw $encryptName && openssl des3 < $tempName > $encryptName -pass pass:$password && sudo chmod -rw $encryptName
  rm $tempName
}

viewFile() {
  filename=$(mapFile "$1")
  temporaryName=$(getTempName "$1")
  setupTemp "$1"
  oldContents=$(cat $temporaryName)
  gedit $temporaryName
  echo "$oldContents"
}

appendToFile () {
  tempFileName=$(getTempName "$1")
  filename=$(mapFile "$1")
  setupTemp "$1"
  echo "$2" >> $tempFileName
  saveAndRemoveTemp $1
}

update () {
  old=$(getValue "$1" "$2")
  echo old "$old"
  tempFileName=$(getTempName "$1")

  setupTemp "$1"
  sed -i "s/$2=.*//g" $tempFileName
  log "$1" "$2" "$old" "Updated"
  saveAndRemoveTemp $1

  appendToFile "$1" "$2=$3"
}

replace() {
  value=$(getValue $1 $2)
  sed -i -re "s/_\{$2\}_/$value/g" $3
}

remove() {
  value=$(getValue $1 $2)
  sed -i -re "s/$value/_{$2}_/g" $3
}


# These are the comments
# That never end
# It goes on and on my friends
case "$1" in
  replace)
    replace $2 $3 $4
  ;;
  remove)
    remove $2 $3 $4
  ;;
  edit)
    oldContents=$(viewFile "$2")
    log $2 "" "" "$oldContents"
    saveAndRemoveTemp "$2"
  ;;
  value)
    getValue "$2" "$3"
  ;;
  append)
    appendToFile "$2" "$3"
  ;;
  update)
    update "$2" "$3" "$4"
  ;;
  map)
    mapFile "$2"
  ;;
  view)
    viewFile "$2"
  ;;
  log)
    $oldContents=$(viewFile "$logId")
    saveAndRemoveTemp "$logId"
  ;;
esac
