#!/bin/bash

SNUM=$(echo $DISPLAY | sed 's/:\([0-9][0-9]*\)/\1/')
xvfb-run -n $SNUM -s "-screen 0 1024x768x24" -f ~/.Xauthority openbox-session &
sleep 1
x11vnc -display $DISPLAY -usepw -forever -quiet &

exec "$@"
