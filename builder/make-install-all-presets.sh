#!/bin/bash
for i in ./presets/*.conf
do
./gen_theme.sh "$i"
done
