#!/bin/sh
echo -ne '\033c\033]0;ZombieStalker\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/ZombieStalker.x86_64" "$@"
