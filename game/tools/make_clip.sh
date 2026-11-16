#!/usr/bin/env bash
# Turns the frames saved by a --record run into playthrough.mp4 and a contact sheet.
set -e
dir="${1:-shots}"
ffmpeg -y -v error -framerate 12 -i "$dir/frames/f_%05d.jpg" -c:v libx264 -pix_fmt yuv420p -crf 26 "$dir/playthrough.mp4"
rm -rf "$dir/frames"
ls -la "$dir/playthrough.mp4"
