#!/bin/sh
i=0
while [ "$i" -lt 200 ]; do
  printf 'stdout-block-0123456789\n'
  i=$((i + 1))
done
i=0
while [ "$i" -lt 200 ]; do
  printf 'stderr-block-0123456789\n' >&2
  i=$((i + 1))
done
