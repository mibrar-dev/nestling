#!/bin/bash
# start_detached.sh NAME CMD... — run a long job in a detached `screen`
# session so it survives the Claude app quitting or restarting.
# Attach: screen -r NAME   List: screen -ls
NAME="$1"; shift
screen -dmS "$NAME" bash -c "cd '$(cd "$(dirname "$0")/../.." && pwd)' && $* ; echo exited >> docs/screens/_status/$NAME.screen.log"
screen -ls | grep -F "$NAME"
