#!/bin/bash -e

declare -A tokens
declare -A fill_rate
declare -A updated_at

now=$(date +%s)

IFS="
"
for redis_key in $(redis-cli keys token_buckets:*)
do
    key="${redis_key#token_buckets:}"
    tokens["$key"]=$(redis-cli hgetall "$redis_key" | head -2 | tail -1)
    fill_rate["$key"]=$(redis-cli hgetall "$redis_key" | head -4 | tail -1)
    updated_at["$key"]=$(date -d "$(redis-cli hgetall "'"'$redis_key'"'" | head -8 | tail -1 | sed s/T/' '/)" +%s)
done

for key in "${!tokens[@]}"
do
    now_toks=$(echo "${tokens[$key]} + ($now-${updated_at[$key]}) * ${fill_rate[$key]}" | bc -l)
    country=
    if [[ $key =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]
    then
        country=$(geoiplookup $key | head -1| cut -d" " -f 5-)
    fi

    # #
    tabs="\t\t"
    [[ ${#key} -gt 16 ]] && tabs="\t"
    echo -e "${key}${tabs}${now_toks}\t$country"
done


# 173.245.67.148
