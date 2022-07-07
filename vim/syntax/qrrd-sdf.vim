" Vim syntax file
" Language:	QRRD Stats Definition File
" Maintainer:	Boris Faure <boris.faure@intersec.com>
" Last Change:	01-12-2010

syntax region qrrdComment   start="^--" skip="\\$" end="$" keepend

hi def link qrrdComment        Comment

let b:current_syntax = "qrrd-sdf"

" vim: ts=8
