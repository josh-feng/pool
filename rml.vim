" File:        rml.vim
" Description: Reduced Markup Language
" Author:      Josh Feng <joshfwisc@gmail.com>
" Licence:     Vim licence
" Website:     http://josh-feng.github.com/pool/
" Version:     1.00
" Version: 1.00
" change log: {{{
"   rml     := '#rml' [hspace+ [attr1]]* [vspace hspace* [assign | comment]]*
"   hspace  := ' ' | '\t'
"   vspace  := '\r'
"   space   := hspace | vspace
"   comment := '#' [pdata] [hspace | ndata]* '\r'
"   assign  := [id] [prop1* | prop2] ':' [hspace+ [comment] [pdata | sdata]] [space+ (ndata | comment)]*
"   prop1   := '|' [attr0 | attr1]
"   prop2   := '|{' [comment+ [attr0 | attr2 ]]* vspace+ '}'
"   attr0   := [&|*] id
"   attr1   := id '=' ndata
"   attr2   := id hspace* '=' (hspace+ | comment) [pdata | sdata]
"   ndata   := [^space]+
"   sdata   := ['|"] .* ['|"]
"   pdata   := '<' [id] '[' id ']' .- '[' id ']>'
"}}}

" quit when a syntax file was already loaded {{{
if exists("b:current_syntax") | finish | endif

scriptencoding utf-8

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
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<\z(\i*\)\[\z(\i*\)\]" end="\[\z2\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@rmlPasteHook

syn match   rmlAssign   +=+ contained containedin=rmlAttr,rmlAttrVal
syn match   rmlSep      +|+ contained containedin=rmlAttr,rmlTagLine,rmlTagName

" attribute
syn match   rmlAttr     contained containedin=rmlTagLine "|[^ |]*[^ |:]"hs=s+1 contains=rmlAssign,rmlSep
syn match   rmlAttrSet  contained containedin=rmlTagProp
    \ "\(^\||{\)\@<=\s*\(\*\|&\)\?\I\i*\(\s\|$\)\@=" nextgroup=rmlComment
syn match   rmlAttrVal  contained containedin=rmlTagProp contains=rmlAssign
    \ "\(^\||{\)\@<=\s*\(\*\|&\)\?\I\i*\s*=" nextgroup=rmlPaste,rmlString

" tag: see cindent
syn match   rmlTagLine  keepend +^\s*\(\(\i\||\)\S*\)\?:\(\s\|$\)\@=+
    \ contains=rmlAttr,rmlSep nextgroup=rmlString,rmlPaste,rmlNormal
syn region  rmlTagProp  keepend matchgroup=rmlTagName nextgroup=rmlString,rmlPaste,rmlNormal
    \ start="^\s*\(\i[^ |{]*\)\?|{\(\s\|$\)\@=" end="^\s*}:\(\s\|$\)\@="
    \ contains=ALLBUT,rmlTagLine,rmlTagProp

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
hi def link rmlSep      Identifier
hi def link rmlAssign   Typedef

hi def link rmlTagName  Identifier
hi def link rmlTagLine  Identifier
hi def link rmlTagProp  NONE

hi def link rmlError    Error
"}}}
let &cpo = s:cpo_save
unlet s:cpo_save
let &cms = ' # %s'
let b:current_syntax = "rml"
" ------------------  paste hook ------------------"{{{
" execute 'syntax include @rmlPasteHook '.$VIMRUNTIME.'/syntax/'.s:paste.'.vim'
" syn include @rmlPasteHook   $VIMRUNTIME/syntax/lua.vim
unlet b:current_syntax
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

unlet b:current_syntax
syn include @rmlPasteHookSh $VIMRUNTIME/syntax/sh.vim
syn region  rmlPaste    matchgroup=rmlCDATA nextgroup=rmlComment fold nextgroup=rmlComment,rmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<\S*sh\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@rmlPasteHookSh

unlet b:current_syntax
syn include @rmlPasteHookMd $VIMRUNTIME/syntax/markdown.vim
syn region  rmlPaste    matchgroup=rmlCDATA nextgroup=rmlComment fold nextgroup=rmlComment,rmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<md\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@rmlPasteHookMd
" ------------------  paste hook ------------------"}}}
" vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
