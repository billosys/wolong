#!/bin/sh
pid_file="$1"
printf '%s\n' "$$" > "$pid_file"
trap '' TERM
printf 'term-resistant-started\n'
printf 'term-resistant-stderr\n' >&2
while :; do
  sleep 1
done
