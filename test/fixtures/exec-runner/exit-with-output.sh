#!/bin/sh
printf 'stdout:ok\n'
printf 'stderr:ok\n' >&2
exit "$1"
