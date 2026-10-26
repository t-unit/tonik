#!/usr/bin/env bash

update_generated_runtime_version() {
  local generator_file="$1"
  local version="$2"
  local expected_count="${3:-1}"
  local pattern="^[[:space:]]*'tonik_util': '\\^[^']+',?$"
  local expected="'tonik_util': '^$version'"
  local match_count

  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
    echo "Error: invalid release version: $version" >&2
    return 1
  fi
  match_count=$(grep -Ec "$pattern" "$generator_file") || true
  if [ "$match_count" != "$expected_count" ]; then
    echo "Error: expected $expected_count tonik_util constraints in $generator_file; found $match_count" >&2
    return 1
  fi

  sed -i.bak -E "s/^([[:space:]]*'tonik_util': '\\^)[^']+(',?)$/\1$version\2/" "$generator_file" || return 1
  rm "$generator_file.bak" || return 1
  local updated_count
  updated_count=$(grep -E "$pattern" "$generator_file" | sed -E 's/^[[:space:]]*//; s/,$//' | grep -Fxc "$expected") || true
  if [ "$updated_count" != "$expected_count" ]; then
    echo "Error: tonik_util constraints in $generator_file do not match ^$version" >&2
    return 1
  fi
}
