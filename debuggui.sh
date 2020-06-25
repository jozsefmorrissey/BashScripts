
DEBUG_REL_DIR=$(dirname "${BASH_SOURCE[0]}")
source $DEBUG_REL_DIR/commandParser.sh
source $DEBUG_REL_DIR/properties.sh


host=${flags[host]}
id=${flags[id]}
group=${flags[group]}

function getConfig() {
  if [ ! -z "$1" ]; then
    propDir=~/.opsc/DebugGui/
    [ ! -d "$propDir" ] && mkdir "$propDir"
    propFileName=default
    if [ ! -z "$id" ]; then
      propFileName=$id
    fi
    propPath="$propDir$propFileName.properties";
    touch "$propPath"
    if [ -z "$host" ]; then
      host=$("$DEBUG_REL_DIR/properties.sh" value "$propPath" host);
    else
      update "$propPath" "host" "$host"
    fi
    if [ -z "$id" ]; then
      id=$($DEBUG_REL_DIR/properties.sh value "$propPath" id);
    else
      update "$propPath" "id" "$id"
    fi

    if [ "config"=="$1" ]; then
      if [ -z "$id" ] && [ -z "$host" ] && [ -z "$group" ]; then
        echo -e "debuggui config failed -id -and -host must be defined\n\tid = '$id'\n\thost = '$host'"
        exit
      fi
    else
      if [ -z "$id" ] && [ -z "$host" ] && [ -z "$group" ]; then
        echo -e "debuggui failed -id -group and -host must be defined\n\tid = '$id'\n\tgroup = '$group'\n\thost = '$host'"
        exit
      fi
    fi
  fi
}

getConfig "$1"

# curlFlags="--silent --output /dev/null -H 'Content-Type: application/json'"
curlFlags="-H 'Content-Type: application/json'"

#call: indent "[string]" "[indention count]"
function indent() {
  trimedStr=$(echo -e "$1" | sed "s/^\s*\(.*\)\s*$/\1/")
  tabStr="\t"
  for (( i=1; i<$(($2)) ; i++ ))
  do
      tabStr="$tabStr\t"
  done
  echo -e "$(echo -e "$trimedStr" | sed "s/\(.*\)/$tabStr\1/g")"
}

function send () {
  mc run debuggui "curl $curlFlags -d $1"
}

function keyValue() {
  send "'{\"key\": \"$1\", \"value\": \"$2\"}' '$host/value/$id/$group'"
}

function link() {
  send "'{\"label\": \"$1\", \"url\": \"$2\"}' '$host/link/$id/$group'"
}

function exception() {
  send "'{\"id\": \"$1\", \"msg\": \"$2\", \"stacktrace\": \"$3\"}' '$host/exception/$id/$group'"
  stack=$(indent "$3" "3")
  message=$(indent "$2" "2")
  header=$(indent "$1")
  echo -e "Exception Thrown:\n$header:\n$message\n$stack"
}

function log() {
  send "'{\"log\": \"$1\"}' '$host/log/$id'"
}

function test() {
  host=http://node.jozsefmorrissey.com/debug-gui
  debuggui keyValue "myKey" "myValue" -host "$host" -id id1 -group app1.value
  debuggui link "myLink" "http://www.google.com" -id id1 -group app1.link
  debuggui log "my very detailed log" -id id1 -group app1.log
  debuggui exception "myException" "myMessage" "\tmyStackTrace\n\tline2\n\tline3" -id id1 -group app1.except

  debuggui keyValue "myKey" "myValue" -id id1 -group app2
  debuggui link "myLink" "http://www.amazon.com" -id id1 -group app2
  debuggui log "my very detailed log" -id id1 -group app2
  debuggui exception "myException" "myMessage" "myStackTrace\nline2\nline3" -id id1 -group app2

  debuggui keyValue "myKey" "myValue" -id id1 -group app3
  debuggui link "myLink" "http://www.google.com" -id id1 -group app3
  debuggui log "my very detailed log" -id id1 -group app3
  debuggui exception "myException" "myMessage" "myStackTrace\nline2\nline3" -id id1 -group app3

  debuggui config  -host "$host" -id id2
  debuggui keyValue "myKey" "myValue" -id id2 -group app4
  debuggui link "myLink" "http://www.google.com" -id id2 -group app4
  debuggui log "my very detailed log" -id id2 -group app2
  debuggui exception "myException" "myMessage" "myStackTrace\nline2\nline3" -id id2 -group app4
}

case $1 in
  # keyValue is used because value throws a grep error... not sure why... command collision???
  keyValue)
    keyValue "$2" "$3"
  ;;
  link)
    link "$2" "$3"
  ;;
  log)
    log "$2"
  ;;
  exception)
    exception "$2" "$3" "$4"
  ;;
  test)
    test
  ;;
  gui)
    xdg-open "$host/html/debug-gui-client-test.html?DebugGui.id=$id&DebugGui.host=$host&DebugGui.debug=true"
  ;;
  install)
    sudo "$DEBUG_REL_DIR/installRef.sh" -cmd debuggui -script "$DEBUG_REL_DIR/debuggui.sh"
  ;;
  config)
    echo "debuggui configuration for '$id' saved"
  ;;
  *)
    flags="\n\t-host \"[host]\"\n\t-id \"[id]\"\n\t-group \"[group]\"\n"
    install="Install globally with command: install\n\n"
    configure="\n\tconfig -host \"[host]\" -id \"[id]\""
    value="\n\tvalue \"[key]\" \"[value]\""
    link="\n\tlink \"[label]\" \"[url]\""
    log="\n\tlog \"[msg]\""
    exception="\n\texception \"[id]\" \"[msg]\" \"[stacktrace]\""
    commands="Availible Commands:$configure$value$link$log$exception"
    echo -e "$install$commands"
  ;;
esac
