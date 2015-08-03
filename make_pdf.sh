#!/bin/sh
pandoc whitepaper.md \
-f markdown \
-t latex --latex-engine=xelatex \
\
# Doesn't work?!
#--number-sections \
#--number-offset=0 \
--filter pandoc-citeproc \
\
-s -o whitepaper.pdf

