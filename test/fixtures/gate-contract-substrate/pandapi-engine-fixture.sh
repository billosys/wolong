#!/bin/sh
set -u

status() {
    printf 'PANDAPI_STATUS\tstatus=%s\tcomponent=engine\tsurface=normal_search\tsurface_disposition=supported\texit_code=%s\tclass=%s\tpartial_output_policy=%s' "$1" "$2" "$3" "$4" >&2
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
scratch=$(mktemp)
trap 'rm -f "$scratch"' EXIT

if [ "$output" != "-" ]; then
    output_dir=$(dirname "$output")
    : >"$output_dir/engine.invoked"
fi

write_artifact() {
    if [ "$output" = "-" ]; then
        cat
    else
        cat >"$output"
    fi
}

if [ "$input" = "-" ]; then
    cat >"$scratch" || {
        status input_unavailable 20 caller_error absent path=- path_role=engine_input operation=read
        exit 20
    }
    input="$scratch"
    input_fields="path=- path_role=engine_input operation=read"
else
    input_fields="path_role=input operation=open"
fi

if [ ! -r "$input" ]; then
    status input_unavailable 20 caller_error absent $input_fields
    exit 20
fi

if grep -q 'malformed' "$input"; then
    status input_invalid 22 input_model_error discarded
    exit 22
fi

if grep -q 'unsolvable' "$input"; then
    printf 'pandapi-engine: search completed with no plan\n' >&2
    status domain_no_plan 2 expected_domain_outcome absent outcome=no_plan $input_fields
    exit 2
fi

if grep -q 'engine-timeout' "$input"; then
    printf 'before-timeout\n'
    printf 'stderr-before-timeout\n' >&2
    trap '' TERM
    sleep 30
fi

if grep -q 'slow-success' "$input"; then
    sleep 1
fi

if grep -q 'engine-output-flood' "$input"; then
    i=0
    while [ "$i" -lt 70000 ]; do
        printf 'x'
        i=$((i + 1))
    done
    printf 'bounded stderr diagnostic\n' >&2
    status ok 0 success complete artifact=stdout outcome=solved $input_fields
    exit 0
fi

printf 'fixture engine plan\n' | write_artifact || {
    status output_unavailable 21 caller_error absent path_role=output operation=open
    exit 21
}

if [ "$output" = "-" ]; then
    status ok 0 success complete artifact=stdout outcome=solved $input_fields
else
    status ok 0 success complete artifact=file outcome=solved $input_fields
fi
exit 0
