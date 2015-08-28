#!/bin/sh
gitcommit=$(git rev-parse HEAD | cut -c -6)
gitdate=$(git show -s --format=%cD)

cat whitepaper.md \
| sed -e 's/{$gitcommit}'"/$gitcommit/" \
| sed -e 's/{$gitdate}'"/$gitdate/" \
| pandoc \
-f markdown \
-t latex --latex-engine=xelatex \
\
--filter pandoc-citeproc \
--chapters \
\
--variable gitcommit="$gitcommit" \
--variable gitdate="$gitdate" \
\
-s -o whitepaper.pdf

# Doesn't work?!
#--number-sections \
#--number-offset=0 \
