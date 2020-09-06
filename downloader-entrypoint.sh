#!/bin/bash

output=$1
input_url=$2

wget -O "$output" "$input_url"

/YoloCR/docker-entrypoint.sh 