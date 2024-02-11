#!/bin/bash

unzip-from-link() {
 local download_link=$1; shift || return 1
 local temporary_dir

 temporary_dir=$(mktemp -d) \
 && curl -LO "${download_link:-}" \
 && unzip -d "$temporary_dir" \*.zip \
 && rm -rf \*.zip \
 && mv "$temporary_dir"/* ${1:-"$HOME/Downloads"} \
 && rm -rf $temporary_dir
}