#!/bin/sh
pandoc whitepaper.md \
-f markdown+footnotes+inline_notes \
-t latex --latex-engine=xelatex \
\
--filter pandoc-citeproc \
\
-s -o whitepaper.pdf

