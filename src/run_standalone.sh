#!/usr/bin/env bash

sleep 1; # Files might not be ready before if this is a restart
echo "----------------"
echo "Starting/restarting python"

# If bot exits, restart
while true ; do
	python -u -m bot.standalone;
	sleep 2;
done
