#!/bin/bash

fileLocation=$1
shift

fileName=$(echo "$fileLocation" | sed 's/^.*\/\([^.]*\)\(.*\)/\1/')
extension=$(echo "$fileLocation" | sed 's/^.*\/\([^.]*\)\(.*\)/\2/')


echo "$fileName     .     $extension"

getLineNumber() {
  echo $(grep -nP "$1$" "$fileLocation" | sed "s/\([0-9]*\):.*/\1/")
}

mkdir "$fileName" 2>/dev/null

echo "$1 $fileName"
headerLineNumber=$(getLineNumber "$1")
echo $headerLineNumber "header"
shift

lastLineNumber=$headerLineNumber;
while [ "$1" != "" ];
do
  lineNumber=$(getLineNumber $1);
  fn="$fileName/to-$lineNumber$extension"
  sed -n "1,${headerLineNumber}p" "$fileLocation" > "$fn"
  sed -n "$lastLineNumber,${lineNumber}p" "$fileLocation" >> "$fn"
  lastLineNumber=$lineNumber
  shift
done

sed -n "1,${headerLineNumber}p" "$fileLocation" > "$fileName/to-end$extension"
sed -n "$lastLineNumber,999999p" "$fileLocation" >> "$fileName/to-end$extension"


# grep -n "LAYER:135" ./C_blum-narrow-rear-bracket-jig.gcode | sed "s/\([0-9]*\):.*/\1/"
