#!/bin/bash

if [ "$1" = "all" ]; then
	echo "building all..."
	mkdir -p ./Debug
	cd Debug
	gcc -Wall -g -o $2.o -I../include ../hid.c ../holtekco2.c ../main.c -ludev
	cd ..
	echo "done."
elif [ "$1" = "clean" ]; then
	echo "cleaning project..."
	rm -f $2/Debug/*.o
	echo "done."
else
	echo "wrong parameter"
	exit 1
fi