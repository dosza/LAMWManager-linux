#!/usr/bin/env bash


source "../core/headers/common-shell.sh"

OLDIFS=$IFS 
IFS="
"
RELEASES_NOTES_PATH=$(realpath ../$(dirname $0))/docs/release_notes.md
RELEASES_NOTES_STREAM=($(<$RELEASES_NOTES_PATH))
RELEASES_NOTES_STREAM_F=()
HEADERS_PATH=$(realpath ../$(dirname $0))/core/headers/lamw_headers

VERSION=$(
	grep "^LAMW_INSTALL_VERSION" $HEADERS_PATH  | 
	awk -F= '{ print $2 }' | sed 's/"//g'
)

INDEX_MATCH_V=0
INDEX_END=0
VERSION_REGEX="$(GenerateScapesStr "$VERSION")"
REGEX_VERSION_DELIMITER='(^###)'

arrayMap  RELEASES_NOTES_STREAM line index '
	if [[ "$line" =~ $VERSION_REGEX ]]; then
		INDEX_MATCH_V=$index
		return
	fi'

RELEASES_NOTES_STREAM=(${RELEASES_NOTES_STREAM[@]:$INDEX_MATCH_V})

arrayMap  RELEASES_NOTES_STREAM line index '
	if [[ "$line" =~ $REGEX_VERSION_DELIMITER ]] && [ $index -gt $INDEX_MATCH_V ]; then
		INDEX_END=$index
		let INDEX_END-=1
		return
	fi'

arraySlice RELEASES_NOTES_STREAM 0 $INDEX_END RELEASES_NOTES_STREAM_F

arrayToString RELEASES_NOTES_STREAM_F
