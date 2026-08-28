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
scratch=$(mktemp)
trap 'rm -f "$scratch"' EXIT

if [ "$output" != "-" ]; then
    output_dir=$(dirname "$output")
    : >"$output_dir/grounder.invoked"
fi

write_artifact() {
    if [ "$output" = "-" ]; then
        cat
    else
        cat >"$output"
    fi
}

large_payload() {
    i=0
    while [ "$i" -lt 70000 ]; do
        printf 'g'
        i=$((i + 1))
    done
    printf '\n'
}

if [ "$input" = "-" ]; then
    cat >"$scratch" || {
        status input_unavailable 20 caller_error absent path=- path_role=htn operation=read
        exit 20
    }
    input="$scratch"
    input_fields="path=- path_role=htn operation=read"
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

if grep -q 'large-grounder' "$input"; then
    {
        printf 'fixture grounder artifact\nlarge-grounder\n'
        large_payload
    } | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'large-engine' "$input"; then
    printf 'fixture grounder artifact\nlarge-engine\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'engine-noisy-stderr' "$input"; then
    printf 'fixture grounder artifact\nengine-noisy-stderr\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'engine-missing-status' "$input"; then
    printf 'fixture grounder artifact\nengine-missing-status\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'engine-flood-timeout' "$input"; then
    printf 'fixture grounder artifact\nengine-flood-timeout\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'engine-invalid' "$input"; then
    printf 'fixture grounder artifact\nmalformed\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'unsolvable' "$input"; then
    printf 'fixture grounder artifact\nunsolvable\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'engine-timeout' "$input"; then
    printf 'fixture grounder artifact\nengine-timeout\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'engine-output-flood' "$input"; then
    printf 'fixture grounder artifact\nengine-output-flood\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'slow-success' "$input"; then
    printf 'fixture grounder artifact\nslow-success\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
else
    printf 'fixture grounder artifact\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
fi

if [ "$output" = "-" ]; then
    status ok 0 success complete artifact=stdout $input_fields
else
    status ok 0 success complete artifact=file $input_fields
fi
exit 0
