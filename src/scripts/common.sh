#!/usr/bin/env bash

function log() {
  echo -e "$@" 1>&2
}

function die() {
  (($# > 0)) && log "$@"
  exit 1
}

function banner() {
  log "\n[=== $@ ===]\n"
}

function find_root() {
  git rev-parse --show-toplevel || \
    die "Failed to find repo root. Are you in a pants_internal clone directory?"
}
