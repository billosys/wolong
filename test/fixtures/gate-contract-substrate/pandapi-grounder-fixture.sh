#!/bin/sh
set -u

status() {
    printf 'PANDAPI_STATUS\tstatus=%s\tcomponent=grounder\tsurface=normal_grounding\tsurface_disposition=supported\texit_code=%s\tclass=%s\tpartial_output_policy=%s' "$1" "$2" "$3" "$4" >&2
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

[ "$#" -eq 5 ] || usage_error
[ "$1" = "--supervised" ] || usage_error
[ "$2" = "--status=stderr" ] || usage_error
[ "$3" = "--output" ] || usage_error

output="$4"
input="$5"
output_dir=$(dirname "$output")
: >"$output_dir/grounder.invoked"

if [ ! -r "$input" ]; then
    status input_unavailable 20 caller_error absent path_role=input operation=open
    exit 20
fi

if grep -q 'malformed' "$input"; then
    status input_invalid 22 input_model_error discarded
    exit 22
fi

if grep -q 'engine-invalid' "$input"; then
    printf 'fixture grounder artifact\nmalformed\n' >"$output" || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'unsolvable' "$input"; then
    printf 'fixture grounder artifact\nunsolvable\n' >"$output" || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
else
    printf 'fixture grounder artifact\n' >"$output" || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
fi

status ok 0 success complete artifact=file
exit 0
