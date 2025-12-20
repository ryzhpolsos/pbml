#!/usr/bin/env bash

if command -v python3 > /dev/null; then
    python3 pbml.py $*
else
    echo "Error: Python executable not found. Make sure you have Python installed"
    if [ -z "$1" ]; then
        read _DUMMY
    fi
fi
