#!/bin/bash

while true; do 
    num=$((1 + RANDOM % 10))
    curl -s -o /dev/null http://istio.gurlal.com/
    curl -s -o /dev/null "http://istio.gurlal.com/post/$num"
    curl -s -o /dev/null "http://istio.gurlal.com/user/$num"
    curl -s -o /dev/null http://istio.gurlal.com/login 
    echo "ID used: $num"
done