#!/bin/bash -e

declare -A tokens
declare -A fill_rate
declare -A updated_at

now=$(date +%s)

IFS="
"
longest_key_len=0
for redis_key in $(redis-cli keys token_buckets:*)
do
    key="${redis_key#token_buckets:}"
    tokens["$key"]=$(redis-cli hgetall "$redis_key" | head -2 | tail -1)
    fill_rate["$key"]=$(redis-cli hgetall "$redis_key" | head -4 | tail -1)
    updated_at["$key"]=$(date -d "$(redis-cli hgetall $redis_key | head -8 | tail -1 | sed s/T/' '/)" +%s)

    [[ ${#key} -gt $longest_key_len ]] && longest_key_len=${#key}
done

total_spacing=`expr \( 8 + $longest_key_len \) / 8 \* 8`

for key in "${!tokens[@]}"
do
    now_toks=$(echo "${tokens[$key]} + ($now-${updated_at[$key]}) * ${fill_rate[$key]}" | bc -l)
    country=
    if [[ $key =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]
    then
        country=$(geoiplookup $key | head -1| cut -d" " -f 5-)
    fi

    # Find required spacing
    num_tabs=`expr 1 + \( $total_spacing - ${#key} - 1 \) / 8` || true # wtf
    total_num_tabs=$num_tabs
    tabs=
    while [ $num_tabs -gt 0 ]
    do
        tabs="\t$tabs"
        num_tabs=`expr $num_tabs - 1` || true # wtf
    done

    # echo $total_spacing
    # echo $longest_key_len
    # echo ${#key}
    # echo $total_num_tabs
    echo -e "${key}${tabs}${now_toks}\t$country"
done

# watch -n 10 "./tokens.sh|sort -nr -k2 -t $'\t'"
# 173.245.67.148
