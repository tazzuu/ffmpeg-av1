#!/bin/bash

# script to do stuff with the video files

# USAGE:
# ./scripts/run.sh input.mkv output.mkv
#
# ACTION=foo ./scripts/run.sh input.mkv output.mkv

set -euo pipefail

INPUT_FILE="${1}"
OUTPUT_FILE="${2}"

INPUT_DIR="$(readlink -f $(dirname "$INPUT_FILE"))"

DEFAULT_CONTAINER="ffmpeg-av1:7.1.1"
CONTAINER="${CONTAINER:-$DEFAULT_CONTAINER}"

DEFAULT_ACTION=cut_section
ACTION="${ACTION:-$DEFAULT_ACTION}"

FFPROBE_BIN="docker run -v $PWD:$PWD --workdir $PWD -v '$INPUT_DIR':'$INPUT_DIR' '$CONTAINER' ffprobe"




get_video_stream_index () {
    # Get video stream index
    local FFPROBE_CMD="$FFPROBE_BIN -v error -select_streams v -show_entries stream=index -of csv=p=0 '$INPUT_FILE'"
    local VIDEO_STREAM=$(eval $FFPROBE_CMD)
    echo "$VIDEO_STREAM"
}

get_stream_indexes_cmd () {
    # Map and copy all non-video streams (audio, subtitles, etc.)
    local CMD=""
    local STREAMS_CMD="$FFPROBE_BIN -v error -show_entries stream=index,codec_type -of csv=p=0 '$INPUT_FILE'"
    local STREAMS=$(eval $STREAMS_CMD)
    while IFS=, read -r INDEX TYPE; do
    if [[ "$TYPE" != "video" ]]; then
        CMD+=" -map 0:$INDEX -c:$INDEX copy"
    fi
    done <<< "$STREAMS"
    echo "$CMD"
}

svt_av1 () {
    local VIDEO_CODEC="libsvtav1"
    local CRF=25
    local PRESET=4
    local VIDEO_STREAM=$(get_video_stream_index)
    local STREAMS_CMD=$(get_stream_indexes_cmd)

    local FFMPEG_BIN="docker run -v $PWD:$PWD --workdir $PWD -v '$INPUT_DIR':'$INPUT_DIR' '$CONTAINER' ffmpeg"

    # Build FFmpeg command
    local FFMPEG_CMD="$FFMPEG_BIN -y -i \"$INPUT_FILE\" -pix_fmt yuv420p10le -g 240 -svtav1-params tune=0"

    # Add video encoding settings
    FFMPEG_CMD+=" -map 0:$VIDEO_STREAM -c:v $VIDEO_CODEC -crf $CRF -preset $PRESET"

    # add streams
    FFMPEG_CMD+="$STREAMS_CMD"

    # Add output file
    FFMPEG_CMD+=" \"$OUTPUT_FILE\""

    # Print and run command
    echo ">>> Generated FFmpeg Command:"
    echo "$FFMPEG_CMD"
    eval $FFMPEG_CMD

}

av1_nvenc () {
    local VIDEO_CODEC="av1_nvenc"
    local CQ=25
    local PRESET=p5
    local VIDEO_STREAM=$(get_video_stream_index)
    local STREAMS_CMD=$(get_stream_indexes_cmd)

    local DOCKER_CMD="docker run --runtime=nvidia --gpus all -e NVIDIA_DRIVER_CAPABILITIES=video -v $PWD:$PWD --workdir $PWD -v '$INPUT_DIR':'$INPUT_DIR' '$CONTAINER'"
    local FFMPEG_BIN="$DOCKER_CMD ffmpeg"

    # Build FFmpeg command
    local FFMPEG_CMD="$FFMPEG_BIN -y -hwaccel cuda -i \"$INPUT_FILE\""

    # Add video encoding settings
    FFMPEG_CMD+=" -map 0:$VIDEO_STREAM -pix_fmt p010le -c:v $VIDEO_CODEC -b:v 0 -cq $CQ -preset $PRESET"

    # add streams
    FFMPEG_CMD+="$STREAMS_CMD"

    # Add output file
    FFMPEG_CMD+=" \"$OUTPUT_FILE\""

    # Print and run command
    echo ">>> Generated FFmpeg Command:"
    echo "$FFMPEG_CMD"
    eval $FFMPEG_CMD
}

av1_vaapi () {
    local CONTAINER="ffmpeg-av1:7.1.1-intel"
    local INTEL_PCI_NODE="$(lspci | grep 'VGA compatible controller: Intel Corporation' | cut -d ' ' -f1)"
    local INTEL_CARD="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-card)"
    local INTEL_RENDER="$(readlink -f /dev/dri/by-path/pci-0000:$INTEL_PCI_NODE-render)"
    local VIDEO_STREAM=$(get_video_stream_index)
    local STREAMS_CMD=$(get_stream_indexes_cmd)

    local DOCKER_CMD="docker run --device=$INTEL_CARD --device=$INTEL_RENDER --group-add video -e MFX_ACCEL_MODE=VAAPI -e MFX_VAAPI_DEVICE=$INTEL_RENDER -v $PWD:$PWD --workdir $PWD -v '$INPUT_DIR':'$INPUT_DIR' '$CONTAINER'"
    local FFMPEG_BIN="$DOCKER_CMD ffmpeg"

    # Build FFmpeg command
    local FFMPEG_CMD="$FFMPEG_BIN -y -init_hw_device vaapi=va:$INTEL_RENDER -hwaccel vaapi -hwaccel_output_format vaapi -i \"$INPUT_FILE\"  -map 0:$VIDEO_STREAM -c:v av1_vaapi "

    # add streams
    FFMPEG_CMD+="$STREAMS_CMD"

    # Add output file
    FFMPEG_CMD+=" \"$OUTPUT_FILE\""

    # Print and run command
    echo ">>> Generated FFmpeg Command:"
    echo "$FFMPEG_CMD"
    eval $FFMPEG_CMD
}

cut_section () {
    # grab a 2min clip 5min into the video file
    FFMPEG_CMD+=$FFMPEG_BIN
    FFMPEG_CMD+=" -y -ss 00:05:00 -i $INPUT_FILE -t 00:02:00 -c copy -avoid_negative_ts make_zero $OUTPUT_FILE"
    set -x
    eval $FFMPEG_CMD
}


case "$ACTION" in

    cut_section)
        echo "do cut_section"
        cut_section
        ;;

    svt_av1)
        svt_av1
        ;;

    av1_nvenc)
        av1_nvenc
        ;;

    av1_vaapi)
        av1_vaapi
        ;;

    *)
        echo ">>> ACTION not recognized: $ACTION"
        ;;
esac