#!/bin/sh
exec 2>/dev/null

if [ \( $# -ne 1 \) -o \( -t 0 \) ]; then
	echo "Usage: getJsonVal 'key' < /tmp/file";
	echo "   -- or -- ";
	echo " cat /tmp/input | getJsonVal 'key'";
	exit 1;
fi;
output=$(python -c "import json,sys;sys.stdout.write(json.dumps(json.load(sys.stdin)$1))";)
#remove all '"'
echo ${output//\"/}
