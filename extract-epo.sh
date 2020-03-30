#!/bin/bash
set -eu

main() {
  local infile infile_extension
  infile="$1"
  infile_extension="${infile##*.}"
  OUTDIR="$(realpath "$infile").files"

  if [[ "$infile_extension" == 'p7s' ]]; then
    local xml_data
    if xml_data="$(decode_p7s "$infile")"; then
      extract_xml <<<"$xml_data"
    fi
  elif [[ "$infile_extension" == 'xml' ]]; then
    extract_xml "$infile"
  else
    err 1 "error: unsupported extension (use .p7s or .xml)\n" || return $?
  fi
}

decode_p7s() {
  local p7s_xml stylesheet p7s_xml_hexdump rc=0

  log "info: verifying the document signature (openssl): "
  p7s_xml="$(openssl smime -inform DER -verify -noverify -in "$1")" || rc=$?
  [[ "$rc" -ne 0 ]] && return "$rc"

  log "info: extracting encoded data\n"
  stylesheet='
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
      <xsl:output omit-xml-declaration="yes"/>
      <xsl:template match="/">
        <xsl:value-of select="/Pisemnost/Data/text()"/>
      </xsl:template>
    </xsl:stylesheet>'
  p7s_xml_hexdump="$(xsltproc <(printf '%s' "$stylesheet") - <<<"$p7s_xml")" || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    err "$rc" "error: data extraction failed\n" || return $?
  fi

  log "info: decoding data\n"
  xxd -r -p <<<"$p7s_xml_hexdump" || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    err "$rc" "error: decoding failed\n" || return $?
  fi
}

extract_xml() {
  local xml stylesheet files
  xml="$(cat "${1:--}")"
  stylesheet='
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
      <xsl:output omit-xml-declaration="yes"/>
      <xsl:template match="/">
        <xsl:for-each select="//Prilohy/ObecnaPriloha">
          <xsl:value-of select="@jm_souboru"/>
          <xsl:text>&#xa;</xsl:text>
        </xsl:for-each>
      </xsl:template>
    </xsl:stylesheet>'

  files="$(xsltproc <(printf '%s' "$stylesheet") - <<<"$xml")"

  if [ -z "$files" ]; then
    err 1 "error: no files found\n" || return $?
  fi
  log "info: extracting files to: %s\n" "$(basename "$OUTDIR")"
  mkdir -p "$OUTDIR"
  cd "$OUTDIR"

  while read -r file; do
    stylesheet='
      <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
        <xsl:output omit-xml-declaration="yes"/>
        <xsl:template match="/">
          <xsl:value-of select="//Prilohy/ObecnaPriloha[@jm_souboru='"'$file'"']/text()"/>
        </xsl:template>
      </xsl:stylesheet>'
    log "info: extracting %s\n" "$file"
    xsltproc <(printf '%s' "$stylesheet") - <<<"$xml" | base64 -d > "$file"
  done <<<"$files"
}

log() {
  printf "$@" >&2
}

err() {
  local e="$1"
  shift
  log "$@"
  return "$e"
}

main "$@"
