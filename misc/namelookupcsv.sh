#!/bin/bash 

FILENAME=$1

if [ ! -n "$FILENAME" ] ; then
	echo "Please supply filename."
	exit 1
fi

for name in `cat "$FILENAME"`; do
   IP=`nslookup $name|awk '/Address/ && $2 !~ /#53/ {print $2}'`
	echo "$name,$IP" >> NameIP.csv
done
