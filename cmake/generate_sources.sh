#!/bin/bash

set -e
echo "-- Generating sources_and_headers.cmake..."

ROOT_DIR=$(pwd)
OUTPUT_FILE="$ROOT_DIR/cmake/sources_and_headers.cmake"
[ -f "$OUTPUT_FILE" ] && rm "$OUTPUT_FILE"

# src/app

APP_DIR="$ROOT_DIR/src/app"
echo "set(APP_SOURCES" >> "$OUTPUT_FILE"
find "$APP_DIR" -type f \( -name "*.h" -o -name "*.cpp" \) | while read -r FILE_PATH; do
    RELATIVE_PATH="${FILE_PATH#"$ROOT_DIR"/}"
    RELATIVE_PATH="${RELATIVE_PATH//\\//}"
    echo "  \${CMAKE_SOURCE_DIR}/$RELATIVE_PATH" >> "$OUTPUT_FILE"
done
echo ")" >> "$OUTPUT_FILE"

# test/*

TEST_DIR="$ROOT_DIR/test"
echo "set(TESTING_SOURCES" >> "$OUTPUT_FILE"
find "$TEST_DIR" -type f \( -name "*.h" -o -name "*.cpp" \) | while read -r FILE_PATH; do
    RELATIVE_PATH="${FILE_PATH#"$ROOT_DIR"/}"
    RELATIVE_PATH="${RELATIVE_PATH//\\//}"
    echo "  \${CMAKE_SOURCE_DIR}/$RELATIVE_PATH" >> "$OUTPUT_FILE"
done
echo ")" >> "$OUTPUT_FILE"

echo "-- Finished generating $OUTPUT_FILE."
