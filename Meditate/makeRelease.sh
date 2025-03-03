#!/bin/bash
# first argument is the app version in format "X.X.X" (e.g. 9.3.2)
VERSION=$1
cd $(dirname "$0")
SEDSTRING='s/about_AppVersion">.*</about_AppVersion">v'${VERSION}'</'
echo "\n$SEDSTRING"
grep -r ./ -e 'about_AppVersion">' | grep -v "bin" | grep -v "makeRelease.sh" | cut -f 1 -d ":" | xargs -n1 -I@ sed -i -e $SEDSTRING @

SEDSTRING='/application/,/products/{s/version=".*"/version="'${VERSION}'"/}'
echo "\n$SEDSTRING"
sed -i -e $SEDSTRING ./manifest.xml 