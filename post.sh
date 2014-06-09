#!/bin/bash

title="$@"
name=$(echo "${title}" | tr -cs '[:alnum:]' - | tr '[:upper:]' '[:lower:]' | sed 's/-$//')
date=$(date --rfc-3339=d)
exec vim "${HOME}/andres.tedx.ee/src/blog/${date}-${name}.md" \
	"+silent read !echo -e title: ${title}\\\\ndate: ${date}\\\\ntags:"
