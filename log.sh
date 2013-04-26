#!/bin/bash

logstep() { local content=$@
    echo "---${content}"
}
logaction() {
    local content=$@
    echo "   * ${content}"
}
logresult() {
    local content=$@
    echo "     ""${content}"
}

listresult() {
    local content=$@
    echo "$content" | (while read l; do
        logresult "$l"
    done)
}
logerror() {
    local content=$@
    echo "     ${content}"
}
listerror() {
    local content=$@
    echo "$content" | (while read l; do
        logerror $l
    done)
}
