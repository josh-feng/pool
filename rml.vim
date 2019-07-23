" Vim syntax file
" Language: Reduced Markup Language
" Maintainer:   Josh Feng <joshfwisc@gmail.com>
" Last Change:  2019 May 07
" Version: 1.00
" change log: {{{
"   rml     := '#rml' [blank+ [attr1]]* blank* '\r' [assign | blank* comment]*
"   blank   := ' ' | '\t'
"   space   := [blank | '\r']+
"   assign  := blank* [id] [prop1* | prop2] ':' [blank+ (pdata | sdata)] [[space (ndata | comment)]* '\r']+
"   comment := '#' ([^\r]*' '\r' | pdata)
"   prop1   := '|' [attr0 | attr1]
"   prop2   := '|{' space [blank* [[attr0 | attr2]] space comment* '\r']* '}'
"   attr0   := id
"   attr1   := id '=' ndata
"   attr2   := id blank* '=' [blank+ (pdata | sdata)]
"   pdata   := '<' [id] '[' id ']' .* '[' id ']>'
"   sdata   := ['|"] .* ['|"] {C-string}
"   ndata   := \S+ {' \#' is replaced w/ ' #'}
"}}}

" quit when a syntax file was already loaded {{{
if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn case match

"syn sync minlines=100
"}}}

" string
syn match   rmlSpecial  contained #\\[\\abfnrtvz'"]\|\\x[[:xdigit:]]\{2}\|\\[[:digit:]]\{,3}#
syn match   rmlSpecial  contained #\\[\\abfnrtv'"[\]]\|\\[[:digit:]]\{,3}#
syn region  rmlString   nextgroup=rmlComment
    \ start=+\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<='+ skip=+\\\\\|\\'+ end=+'\(\s\|$\)\@=+
    \ contains=rmlSpecial,@Spell
syn region  rmlString   nextgroup=rmlComment
    \ start=+\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<="+ skip=+\\\\\|\\"+ end=+"\(\s\|$\)\@=+
    \ contains=rmlSpecial,@Spell

" consume paste and string
syn match   rmlNormal   +\S*[:=]\s[^ #]+ nextgroup=rmlNormal,rmlTagLine,rmlTagProp,rmlComment
syn match   rmlError    contained containedin=rmlTagProp +[^ '"#]\S*+

" verbatim block
syn region  rmlPaste    matchgroup=rmlCDATA fold nextgroup=rmlComment,rmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<\z(\i*\)\[\z([^\]]*\)\]" end="\[\z2\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@rmlPasteHook

" attribute
syn match   rmlAttr     contained containedin=rmlTagLine "|[^ |]*[^ |:]"hs=s+1
syn match   rmlAttrSet  contained containedin=rmlTagProp
    \ "\(^\||{\)\@<=\s*\(\*\|&\)\?\I\i*\(\s\|$\)\@=" nextgroup=rmlComment
syn match   rmlAttrVal  contained containedin=rmlTagProp
    \ "\(^\||{\)\@<=\s*\(\*\|&\)\?\I\i*\s*=" nextgroup=rmlPaste,rmlString

" tag: see cindent
syn match   rmlTagLine  keepend +^\s*\(\(\i\||\)\S*\)\?:\(\s\|$\)\@=+
    \ contains=rmlAttr nextgroup=rmlPaste,rmlString,rmlNormal
syn region  rmlTagProp  matchgroup=rmlTagName nextgroup=rmlPaste,rmlString,rmlNormal
    \ start="^\s*\(\i[^ |{]*\)\?|{\(\s\|$\)\@=" end="^\s*}:\(\s\|$\)\@="
    \ extend contains=ALLBUT,rmlTagLine,rmlTagProp,rmlAttr

" comment
syn keyword rmlTodo     contained TODO FIXME XXX
syn match   rmlComment  keepend +\(^\|\s\)#.*$+ contains=rmlTodo,@Spell
syn region  rmlComment  matchgroup=rmlComment fold
    \ start="\(^\|\s\+\)#<\w*\[\z([^\]]*\)\]" end="#\[\z1\]>.*$"
    \ contains=rmlTodo,@Spell,@rmlPasteHook

" The default highlighting."{{{
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
"}}}
let b:current_syntax = "rml"

" ------------------  paste hook ------------------"{{{
unlet b:current_syntax
" execute 'syntax include @rmlPasteHook '.$VIMRUNTIME.'/syntax/'.s:paste.'.vim'
" syn include @rmlPasteHook   $VIMRUNTIME/syntax/lua.vim
syn include @rmlPasteHookLua $VIMRUNTIME/syntax/lua.vim
syn region  rmlPaste    matchgroup=rmlCDATA nextgroup=rmlComment fold nextgroup=rmlComment,rmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<lua\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@rmlPasteHookLua

unlet b:current_syntax
syn include @rmlPasteHookTex $VIMRUNTIME/syntax/tex.vim
syn region  rmlPaste    matchgroup=rmlCDATA nextgroup=rmlComment fold nextgroup=rmlComment,rmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<tex\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@rmlPasteHookTex

unlet b:current_syntax
syn include @rmlPasteHookCpp $VIMRUNTIME/syntax/cpp.vim
syn region  rmlPaste    matchgroup=rmlCDATA nextgroup=rmlComment fold nextgroup=rmlComment,rmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<cpp\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@rmlPasteHookCpp
" ------------------  paste hook ------------------"}}}

let &cpo = s:cpo_save
unlet s:cpo_save

let &cms = ' # %s'
" vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
