#!/bin/sh
pid_file="$1"
cat >/dev/null
printf '%s\n' "$$" > "$pid_file"
trap '' TERM
printf 'stdin-term-resistant-started\n'
printf 'stdin-term-resistant-stderr\n' >&2
while :; do
  sleep 1
done
