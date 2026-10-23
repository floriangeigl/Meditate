#!/bin/bash
# fails when a manifest device has no complete SDK device folder; the compiler only warns
# "Invalid device id" and leaves that device out of the build and the store package
cd "$(dirname "$0")"
if [ -n "$APPDATA" ]; then
	DEVICES="$APPDATA/Garmin/ConnectIQ/Devices"
else
	DEVICES="$HOME/.Garmin/ConnectIQ/Devices"
fi

IDS=$(grep -o '<iq:product id="[^"]*"' Meditate/manifest.xml | cut -d '"' -f 2)
BROKEN=""
for ID in $IDS; do
	for FILE in compiler.json simulator.json "$ID.bin"; do
		if [ ! -s "$DEVICES/$ID/$FILE" ]; then
			BROKEN="$BROKEN\n  $ID: $FILE missing"
		fi
	done
done

COUNT=$(echo "$IDS" | wc -w)
if [ -n "$BROKEN" ]; then
	echo -e "Incomplete device folders in $DEVICES:$BROKEN"
	echo "Download these devices again in the SDK Manager."
	exit 1
fi
echo "All $COUNT manifest devices have a complete device folder."
