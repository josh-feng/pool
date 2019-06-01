" Vim syntax file
" Language: Reduced Markup Language
" Maintainer:   Josh Feng <joshfwisc@gmail.com>
" Last Change:  2019 May 07
" Version: 0.99
" change log:
"   TODO hook BNF
"
"   rml     := '#rml' [blank+ attr1]* '\r' [assign comment]*
"   id      := [A-Za-z0-9_][A-Za-z0-9_:.]*
"   blank   := (' ' | '\t')
"   space   := [blank | '\r']+
"   comment := [space '#' [^\r]*] '\r'
"   tag     := [id] [['|' [attr0 | attr1 ]]* | ('|{' [[attr0 | attr2] comment]* '}')]
"   attr0   := id
"   attr1   := id '=' ndata
"   attr2   := id blank* '=' [blank+ (pdata | sdata)]
"   assign  := blank+ tag ':' [blank+ (pdata | sdata)] [[blank+ ndata]* comment]*
"   pdata   := '<' [id] '[' id ']' .* '[' id ']>'
"   sdata   := '[^']' # skip \' honor escape
"   ndata   := \S+

" quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn case match

"syn sync minlines=100

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
    \ start=+\(:\s\|=\s\)\@<='+ skip=+\\\\\|\\'+ end=+'+ contains=rmlSpecial,@Spell
syn region rmlString  nextgroup=rmlComment
    \ start=+\(:\s\|=\s\)\@<="+ skip=+\\\\\|\\"+ end=+"+ contains=rmlSpecial,@Spell

" consume paste and string
syn match  rmlNormal  +\S*[:=]\s[^ #]+ nextgroup=rmlNormal,rmlTagLine,rmlTagProp,rmlComment
syn match  rmlError   contained containedin=rmlTagProp +[^ '"#]\S*+

" verbatim block
syn region rmlPaste   matchgroup=rmlCDATA nextgroup=rmlComment fold nextgroup=rmlComment,rmlError
    \ start="\(:\s\|=\s\)\@<=<\w*\[\z([^\]]*\)\]" end="\[\z1\]>" extend contains=@Spell,@rmlPasteHook

" attribute
syn match  rmlAttr    contained containedin=rmlTagLine "|[^ |]*[^ |:]"hs=s+1
syn match  rmlAttrSet contained containedin=rmlTagProp "\(^\||{\)\@<=\s*\I\i*\(\s\|$\)\@="
    \ nextgroup=rmlComment,relComArea
syn match  rmlAttrVal contained containedin=rmlTagProp "\(^\||{\)\@<=\s*\I\i*\s*="
    \ nextgroup=rmlPaste,rmlString

" tag: see cindent
syn match  rmlTagLine keepend +^\s*\S*:\(\s\|$\)\@=+ contains=rmlAttr nextgroup=rmlPaste,rmlString,rmlNormal
syn region rmlTagProp keepend matchgroup=rmlTagName nextgroup=rmlPaste,rmlString,rmlNormal
    \ start="^\s*[^ |{]*|{\(\s\|$\)\@=" end="\s*}:\(\s\|$\)\@="
    \ contains=ALLBUT,rmlTagLine,rmlTagProp,rmlAttr

" The default highlighting.
" highlight Folded term=bold ctermbg=blue ctermfg=cyan guibg=grey guifg=blue

hi def link rmlTodo     Todo
hi def link rmlComment  Comment

hi def link rmlString   String
hi def link rmlCDATA    Folded

hi def link rmlAttr     Statement
hi def link rmlAttrSet  Statement
hi def link rmlAttrVal  Statement
" hi def link rmlAttrSet  Typedef
" hi def link rmlAttrVal  Typedef

hi def link rmlTagName  Identifier
hi def link rmlTagLine  Identifier
hi def link rmlTagProp  NONE

hi def link rmlError    Error

let b:current_syntax = "rml"

" syntax include @Paste   $HOME/.vim/syntax/paste.vim
" syntax region rmlCdata  contained start="<\w*\[\z([^\]]*\)\]" end="\[\z1\]>" contains=@Paste keepend

let &cpo = s:cpo_save
unlet s:cpo_save

let &cms = ' # %s'
" vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
