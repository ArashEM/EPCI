#!/bin/bash

index=1
app="./build/mem_bt"


# check if test application is built
if [ ! -f "$app" ]; then 
    echo "$app dose not exist"
    echo "run make first"
    exit -1
fi


# call test application in loop
while [ $index -le 100 ] 
do
    ./$app
    #check return value 
    if [ $? -ne 0 ]; then
        echo "error in iteration $index"
        exit -1
    fi
    sleep 0.1
    index=$(( $index + 1))
done
