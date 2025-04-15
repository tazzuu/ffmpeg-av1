#!/bin/bash

# https://docs.nvidia.com/video-technologies/video-codec-sdk/12.0/ffmpeg-with-nvidia-gpu/index.html

set -euo pipefail

INPUT_FILE="$1"
OUTPUT_FILE="$2"
VIDEO_CODEC="av1_nvenc"
CQ=25
PRESET=p5
INPUT_DIR="$(readlink -f "$(dirname "$INPUT_FILE")" )"

CONTAINER=ffmpeg-av1:7.1.1
DOCKER_CMD="docker run --runtime=nvidia --gpus all -e NVIDIA_DRIVER_CAPABILITIES=video -v $PWD:$PWD --workdir $PWD -v '$INPUT_DIR':'$INPUT_DIR' '$CONTAINER'"
FFMPEG_BIN="$DOCKER_CMD ffmpeg"
FFPROBE_BIN="$DOCKER_CMD ffprobe"
FFPROBE_CMD="$FFPROBE_BIN -v error -select_streams v -show_entries stream=index -of csv=p=0 '$INPUT_FILE'"

# Get video stream index
VIDEO_STREAM=$(eval $FFPROBE_CMD)

# Build FFmpeg command
FFMPEG_CMD="$FFMPEG_BIN -y -hwaccel cuda -i \"$INPUT_FILE\""

# Add video encoding settings
FFMPEG_CMD+=" -map 0:$VIDEO_STREAM -pix_fmt p010le -c:v $VIDEO_CODEC -b:v 0 -cq $CQ -preset $PRESET"

# Map and copy all non-video streams (audio, subtitles, etc.)
STREAMS_CMD="$FFPROBE_BIN -v error -show_entries stream=index,codec_type -of csv=p=0 '$INPUT_FILE'"
STREAMS=$(eval $STREAMS_CMD)

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