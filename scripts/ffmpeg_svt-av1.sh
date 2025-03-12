#!/bin/bash
set -euo pipefail

INPUT_FILE="$1"
OUTPUT_FILE="$2"
VIDEO_CODEC="libsvtav1"
CRF=25
PRESET=4

CONTAINER=ffmpeg-av1:7.1.1
FFMPEG_BIN="docker run -v $PWD:$PWD --workdir $PWD $CONTAINER ffmpeg"
FFPROBE_BIN="docker run -v $PWD:$PWD --workdir $PWD $CONTAINER ffprobe"

# Get video stream index
VIDEO_STREAM=$($FFPROBE_BIN -v error -select_streams v -show_entries stream=index -of csv=p=0 "$INPUT_FILE")

# Build FFmpeg command
FFMPEG_CMD="$FFMPEG_BIN -y -i \"$INPUT_FILE\" -pix_fmt yuv420p10le -g 240 -svtav1-params tune=0"

# Add video encoding settings
FFMPEG_CMD+=" -map 0:$VIDEO_STREAM -c:v $VIDEO_CODEC -crf $CRF -preset $PRESET"

# Map and copy all non-video streams (audio, subtitles, etc.)
STREAMS=$($FFPROBE_BIN -v error -show_entries stream=index,codec_type -of csv=p=0 "$INPUT_FILE")

while IFS=, read -r INDEX TYPE; do
  if [[ "$TYPE" != "video" ]]; then
    FFMPEG_CMD+=" -map 0:$INDEX -c:$INDEX copy"
  fi
done <<< "$STREAMS"

# Add output file
FFMPEG_CMD+=" \"$OUTPUT_FILE\""

# Print and run command
echo "Generated FFmpeg Command:"
echo "$FFMPEG_CMD"
eval $FFMPEG_CMD