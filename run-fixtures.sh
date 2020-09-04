#!/bin/bash

LOCAL_URL=http://localhost:3000/determinations/eval
REFERENCE_URL=https://www.medicaideligibilityapi.org/determinations/eval

base_args=(-H "Authorization: Token token=$(cat .token)" -H 'Accept: application/json' -H 'Content-type: application/json')

if [[ $# -gt 0 ]]; then
    files=( "$@" )
else
    files=( ./test/fixtures/*.json )
fi

for fixture in "${files[@]}"; do
    echo -n "Running fixture $fixture ... "
    diff -U2 <(curl "${base_args[@]}" -d "@$fixture" "$REFERENCE_URL" 2>/dev/null) \
             <(curl "${base_args[@]}" -d "@$fixture" "$LOCAL_URL" 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        echo 'same'
    else
        echo 'different'
    fi
done
