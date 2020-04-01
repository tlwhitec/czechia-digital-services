#!/bin/bash
set -eu

main() {
  local infile infile_extension
  infile="$1"
  infile_extension="${infile##*.}"
  OUTDIR="$(realpath "$infile").files"

  if [[ "$infile_extension" == 'zfo' ]]; then
    extract_zfo "$infile"
  else
    err 1 "error: unsupported extension (use .zfo)\n" || return $?
  fi
}

extract_zfo() {
  local xml rc=0 stylesheet files

  log "info: verifying the document signature (openssl): "
  xml="$(openssl smime -inform DER -verify -noverify -in "$1")" || rc=$?
  [[ "$rc" -ne 0 ]] && return "$rc"

  stylesheet='
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
      <xsl:output omit-xml-declaration="yes"/>
      <xsl:template match="/">
        <xsl:for-each select="'"//*[local-name()='dmFile']"'">
          <xsl:value-of select="@dmFileDescr"/>
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
          <xsl:value-of select="'"//*[local-name()='dmFile' and @dmFileDescr='$file']/*[local-name()='dmEncodedContent']/text()"'"/>
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
