" Vim syntax file
" Language: Reduced Markup Language
" Maintainer:   Josh Feng <joshfwisc@gmail.com>
" Last Change:  2019 May 07

" quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn case match

" version 0.9
"syn sync minlines=100

" rml   := '#rml' [blank* attr1]* '\r' [assign | comment]*
" blank := ' ' | '\t'
" space := blank+ | '\r'
" tag   := [identifier] [['|' [attr0 | attr1 ]]* | '|{' [attr1 | attr2]* '}']
" attr0 := [alphanum]+
" attr1 := [alphanum]+ '=' normal_data | string_data
" assign := tag blank+ comment [pasted_data | string_data | normal_data]
" comment := [^ | space]@ '#' [alphanum]* '\r'
" identifier := [alphanum]*
" delimiter := [alphanum]*
" pasted_data := verbatim
" string_data := honor escaped characters (space counts)
" normal_data := indentation control w/ comment # (non-comment \#)

" comment
syn keyword rmlTodo     contained TODO FIXME XXX
syn match   rmlComment  keepend +\(^\|\s\)#.*$+ contains=rmlTodo,@Spell
syn region  rmlComment  matchgroup=rmlComment fold
    \ start="\(^\|\s\+\)#<\w*\[\z([^\]]*\)\]" end="\[\z1\]>"
    \ contains=rmlTodo,@Spell,@rmlPasteHook

" string
syn match  rmlSpecial contained #\\[\\abfnrtvz'"]\|\\x[[:xdigit:]]\{2}\|\\[[:digit:]]\{,3}#
syn match  rmlSpecial contained #\\[\\abfnrtv'"[\]]\|\\[[:digit:]]\{,3}#
syn region rmlString  nextgroup=rmlComment
    \ start=+\(^\|\s\)\@<='+ skip=+\\\\\|\\'+ end=+'+ contains=rmlSpecial,@Spell
syn region rmlString  nextgroup=rmlComment
    \ start=+\(^\|\s\)\@<="+ skip=+\\\\\|\\"+ end=+"+ contains=rmlSpecial,@Spell

syn match  rmlError   contained containedin=rmlTagProp "[^ '"#]\S*"

" verbatim block
syn region rmlPaste   matchgroup=rmlCDATA nextgroup=rmlComment fold
    \ start="\(^\|\s\)\@<=<\w*\[\z([^\]]*\)\]" end="\[\z1\]>" extend contains=@Spell,@rmlPasteHook

" attribute
syn match  rmlAttr    contained containedin=rmlTagLine "|[^ |]*[^ |:]"hs=s+1
syn match  rmlAttrSet contained containedin=rmlTagProp "^\s*\I\i*\(\s\|$\)\@="
    \ nextgroup=rmlComment,relComArea
syn match  rmlAttrVal contained containedin=rmlTagProp "^\s*\I\i*\s*="
    \ nextgroup=rmlPaste,rmlString

" tag: see cindent
syn match  rmlTagLine keepend +^\s*\S*:\(\s\|$\)\@=+ contains=rmlAttr
syn region rmlTagProp keepend matchgroup=rmlTagName
    \ start="^\s*[^ |{]*|{" end="^\s*}:\(\s\|$\)\@="
    \ contains=ALLBUT,rmlTagLine,rmlTagProp,rmlAttr,rmlError

" The default highlighting.
" highlight Folded term=bold ctermbg=blue ctermfg=cyan guibg=grey guifg=blue

hi def link rmlTodo     Todo
hi def link rmlComment  Comment

hi def link rmlString   String
hi def link rmlCDATA    Folded

hi def link rmlAttr     Statement
hi def link rmlAttrSet  Statement
hi def link rmlAttrVal  Statement
"hi def link rmlAttrSet  Typedef
"hi def link rmlAttrVal  Typedef

hi def link rmlTagName  Identifier
hi def link rmlTagLine  Identifier
hi def link rmlTagProp  NONE

hi def link rmlError    Error

let b:current_syntax = "rml"

" syntax include @Paste   $HOME/.vim/syntax/paste.vim
" syntax region rmlCdata  contained start="<\w*\[\z([^\]]*\)\]" end="\[\z1\]>" contains=@Paste keepend

let &cpo = s:cpo_save
unlet s:cpo_save
" vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
