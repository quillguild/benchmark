#!/bin/bash

# MIT License
# Copyright (c) 2020 Radek Ziemniewicz

usage () {
    me=$(basename "$0")

    echo "No arguments provided"
    echo
    echo "Use example:"
    echo "./${me} php ../test.php 10 2"
    echo
    echo "Where:"
    echo "- 10 is a total number of calls"
    echo "- 2 is number of concurrent requests"
    echo
    exit 1
}

get_milliseconds () {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        date +%s%N | cut -b1-13
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        python -c 'from time import time; print int(round(time() * 1000))'
    fi
}

if [ $# -lt 3 ]; then usage; fi

command=$1
requests=$2
parallel=$3

result=$($command 2>&1)

if [[ ! $result =~ ^[0-9]+\.?[0-9]*$ ]]
then
    echo "Script not found or the result format is not float with a new line at the end (e.g. 1.2321)"

    exit 2
fi

start_time=$(get_milliseconds)

log_file="output_command_${requests}_${parallel}_${start_time}.log"
echo -n '' > $log_file

seq 1 $requests | xargs -I $ -n1 -P${parallel} $command >> $log_file

end_time=$(get_milliseconds)

took=$(($end_time - $start_time))
took_seconds=$(awk "BEGIN {printf \"%.6f\",$took/1000}")
per_second=$(awk "BEGIN {printf \"%.6f\",$requests/$took_seconds}")
total_time_operation=$(sed 's/ //g' $log_file | tr '\n' '+' | sed 's/+$//g' | sed 's/++/+/g')
total_time=$(echo ${total_time_operation} | bc -l)
avg_time=$(awk "BEGIN {printf \"%.6f\",$total_time/$requests}")

rm $log_file

echo
echo -n "${requests} calls, "
echo "${parallel} concurrently"

echo "Command \`${command}\`"

echo '-------------------------------------------------------------------'
echo -n "Took ${took_seconds} s, "
echo -n "${per_second} calls per second, "
echo -n "${avg_time} avg call time"
echo
echo
