#!/bin/sh
gitcommit=$(git rev-parse HEAD)
gitdate=$(git show -s --format=%ci)

pandoc whitepaper.md \
-f markdown \
-t latex --latex-engine=xelatex \
\
--filter pandoc-citeproc \
--chapters \
\
--variable gitcommit "$gitcommit"
--variable gitdate "$gitdate"
\
-s -o whitepaper.pdf

# Doesn't work?!
#--number-sections \
#--number-offset=0 \
