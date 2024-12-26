#!/bin/bash

export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus

if type ibus-daemon >/dev/null 2>&1; then
    ibus-daemon -drx
fi
