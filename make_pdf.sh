#!/bin/sh
pandoc whitepaper.md \
-f markdown \
-t latex --latex-engine=xelatex \
\
--filter pandoc-citeproc \
\
-s -o whitepaper.pdf

# Doesn't work?!
#--number-sections \
#--number-offset=0 \
