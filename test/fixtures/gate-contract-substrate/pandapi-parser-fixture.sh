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

if [ "$domain" = "-" ] && [ "$problem" = "-" ]; then
    status cli_usage_error 10 caller_error absent path_role=parser_input operation=read
    exit 10
fi

if [ "$output" != "-" ]; then
    output_dir=$(dirname "$output")
    : >"$output_dir/parser.invoked"
fi

write_artifact() {
    if [ "$output" = "-" ]; then
        cat
    else
        cat >"$output"
    fi
}

if [ ! -r "$domain" ]; then
    status input_unavailable 20 caller_error absent path_role=domain operation=open
    exit 20
fi

if [ ! -r "$problem" ]; then
    status input_unavailable 20 caller_error absent path_role=problem operation=open
    exit 20
fi

if grep -q 'force-grounder-invalid' "$domain"; then
    printf 'fixture parser artifact\nmalformed\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'force-engine-invalid' "$domain"; then
    printf 'fixture parser artifact\nengine-invalid\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'force-engine-timeout' "$domain"; then
    printf 'fixture parser artifact\nengine-timeout\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'force-engine-output-flood' "$domain"; then
    printf 'fixture parser artifact\nengine-output-flood\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'force-slow-success' "$domain"; then
    printf 'fixture parser artifact\nslow-success\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
elif grep -q 'wolong-unsolvable' "$domain"; then
    printf 'fixture parser artifact\nunsolvable\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
else
    printf 'fixture parser artifact\n' | write_artifact || {
        status output_unavailable 21 caller_error absent path_role=output operation=open
        exit 21
    }
fi

if [ "$output" = "-" ]; then
    status ok 0 success complete artifact=stdout
else
    status ok 0 success complete artifact=file
fi
exit 0
