#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
title="$@"
date=$(date --rfc-3339=d)
name=$(echo "${date}-${title}" | tr -cs '[:alnum:]' - | tr '[:upper:]' '[:lower:]' | sed 's/-$//')

cd $DIR
gvim -n "$DIR/src/blog/${name}.md" \
	"+silent read !echo -e title: ${title}\\\\ndate: ${date}\\\\ntags:" \
	"+silent set directory \"${DIR}\""
gostatic -w config
