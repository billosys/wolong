#!/bin/sh
payload=$(cat)
printf 'arg:%s\n' "$1"
printf 'stdin:%s\n' "$payload"
printf 'stderr:%s\n' "$payload" >&2
