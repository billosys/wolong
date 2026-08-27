#!/bin/sh
status="$1"
payload=$(cat)
printf 'stdin:%s\n' "$payload"
printf 'stderr:%s\n' "$payload" >&2
exit "$status"
