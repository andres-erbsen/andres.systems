#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "USAGE: $0 TITLE [TITLE...]" >&2
    exit 2
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
title="$@"
date=$(date --rfc-3339=d)
name=$(echo "${date}-${title}" | tr -cs '[:alnum:]' - | tr '[:upper:]' '[:lower:]' | sed 's/-$//')

cd "$DIR" &
vim -n "$DIR/src/blog/${name}.md" \
	"+silent read !echo -e title: ${title}\\\\ndate: ${date}\\\\ntags:\\\\n----\\\\n" \
	"+silent set directory \"${DIR}\""
make
