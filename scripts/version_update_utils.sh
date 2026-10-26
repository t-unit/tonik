#!/usr/bin/env bash

update_generated_runtime_version() {
  local generator_file="$1"
  local version="$2"
  local pattern="^[[:space:]]*'tonik_util': '\\^[^']+',?$"
  local expected="'tonik_util': '^$version'"
  local match_count

  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
    echo "Error: invalid release version: $version" >&2
    return 1
  fi
  match_count=$(grep -Ec "$pattern" "$generator_file") || true
  if [ "$match_count" != 1 ]; then
    echo "Error: expected exactly one generated tonik_util constraint in $generator_file; found $match_count" >&2
    return 1
  fi

  sed -i.bak -E "s/^([[:space:]]*'tonik_util': '\\^)[^']+(',?)$/\1$version\2/" "$generator_file" || return 1
  rm "$generator_file.bak" || return 1
  local actual
  actual=$(grep -E "$pattern" "$generator_file" | sed -E 's/^[[:space:]]*//; s/,$//')
  if [ "$actual" != "$expected" ]; then
    echo "Error: generated tonik_util constraint does not match ^$version" >&2
    return 1
  fi
}
