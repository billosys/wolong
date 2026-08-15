#!/bin/sh
set -u

status() {
    printf 'PANDAPI_STATUS\tstatus=%s\tcomponent=parser\tsurface=normal_parse\tsurface_disposition=supported\texit_code=%s\tclass=%s\tpartial_output_policy=%s' "$1" "$2" "$3" "$4" >&2
    shift 4
    while [ "$#" -gt 0 ]; do
        printf '\t%s' "$1" >&2
        shift
    done
    printf '\n' >&2
}

usage_error() {
    status cli_usage_error 10 caller_error absent
    exit 10
}

[ "$#" -eq 6 ] || usage_error
[ "$1" = "--supervised" ] || usage_error
[ "$2" = "--status=stderr" ] || usage_error
[ "$3" = "--output" ] || usage_error

output="$4"
domain="$5"
problem="$6"
output_dir=$(dirname "$output")
: >"$output_dir/parser.invoked"

if [ ! -r "$domain" ]; then
    status input_unavailable 20 caller_error absent path_role=domain operation=open
    exit 20
fi

if [ ! -r "$problem" ]; then
    status input_unavailable 20 caller_error absent path_role=problem operation=open
    exit 20
fi

if grep -q 'force-grounder-invalid' "$domain"; then
    printf 'fixture parser artifact\nmalformed\n' >"$output" || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'force-engine-invalid' "$domain"; then
    printf 'fixture parser artifact\nengine-invalid\n' >"$output" || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'force-engine-timeout' "$domain"; then
    printf 'fixture parser artifact\nengine-timeout\n' >"$output" || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'force-slow-success' "$domain"; then
    printf 'fixture parser artifact\nslow-success\n' >"$output" || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'wolong-unsolvable' "$domain"; then
    printf 'fixture parser artifact\nunsolvable\n' >"$output" || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
else
    printf 'fixture parser artifact\n' >"$output" || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
fi

status ok 0 success complete artifact=file
exit 0
