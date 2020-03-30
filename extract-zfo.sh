#!/bin/sh
set -eu
input="$1"
xml="$input.xml"
openssl smime -inform DER -in "$input" -verify -noverify -out "$xml"
trap 'rm -f "$xml"' EXIT
xml="$(realpath "$xml")"
files=$(xmllint --xpath "string(//*[local-name()='dmFile']/@dmFileDescr)" "$xml")
if [ -z "$files" ]; then
  echo "No files found!"; exit 1
fi
echo "Found the following files: $files"
outdir="$(basename "$input")"
outdir="${outdir%.*}"
echo "Extracting them to: $(pwd)/$outdir"
mkdir -p "$outdir"
cd "$outdir"
for file in $files; do
    echo "Extracting $file"
    xmllint --xpath "//*[local-name()='dmFile' and @dmFileDescr='$file']/*[local-name()='dmEncodedContent']/text()" "$xml" | base64 -d > "$file"
done
