"==================================================
" File:         echofunc.vim
" Brief:        Echo the function declaration in
"               the command line for C/C++.
" Author:       Mingbai <mbbill AT gmail DOT com>
" Last Change:  2006-12-21 23:47:31
" Version:      1.1
"
" Install:      1. Put echofunc.vim to /plugin directory.
"               2. Use the command below to reate tags 
"                  file including signature field.
"                  ctags --fields=+S .
"
" Usage:        When you type '(' after a function name 
"               in insert mode, the function declaration
"               will be displayed in the command line
"               automatically. Then use ctrl+n, ctrl+b to
"               cycle between function declarations (if exists).
"               
"==================================================

let s:res=[]
let s:count=1
let s:bShowMode=&showmode
let s:CmdHeight=&cmdheight
autocmd BufReadPost * call EchoFuncStart()
menu        &Tools.Echo\ Function\ Start          :call EchoFuncStart()<CR>
menu        &Tools.Echo\ Function\ Stop           :call EchoFuncStop()<CR>

function! s:EchoFuncDisplay()
    set noshowmode
    let wincolumn=&columns
    if len(s:res[s:count-1]) > (wincolumn-12)
        set cmdheight=2
    else
        set cmdheight=1
    endif
    echohl Type | echo s:res[s:count-1] | echohl None
endfunction

function! EchoFunc()
    let fun=substitute(getline('.')[:(col('.'))],'\zs.*\W\ze\w*$','','g') " get function name
    let ftags=taglist(fun)
    if type(ftags)==type(0) || ((type(ftags)==type([])) && ftags==[])
        return
    endif
    let fil_tag=[]
    for i in ftags
        if has_key(i,'kind') && has_key(i,'name') && has_key(i,'signature')
            if (i.kind=='p' || i.kind=='f') && i.name==fun  " p is declare, f is defination
                let fil_tag+=[i]
            endif
        endif
    endfor
    if fil_tag==[]
        return
    endif
    let s:res=[]
    let s:count=1
    for i in fil_tag
        let name=substitute(i.cmd[2:],i.name.'.*','','g').i.name.i.signature
        let s:res+=[name.' ('.(index(fil_tag,i)+1).'/'.len(fil_tag).') '.i.filename]
    endfor
    call s:EchoFuncDisplay()
endfunction

function! EchoFuncN()
    if s:res==[]
        return
    endif
    if s:count==len(s:res)
        let s:count=1
    else
        let s:count+=1
    endif
    call s:EchoFuncDisplay()
endfunction

function! EchoFuncP()
    if s:res==[]
        return
    endif
    if s:count==1
        let s:count=len(s:res)
    else
        let s:count-=1
    endif
    call s:EchoFuncDisplay()
endfunction

function! EchoFuncStart()
    inoremap    <silent>    <buffer>    (       <c-r>=EchoFunc()<cr><bs>(
    inoremap    <silent>    <buffer>    <m-n>   <c-r>=EchoFuncN()<cr><bs>
    inoremap    <silent>    <buffer>    <m-b>   <c-r>=EchoFuncP()<cr><bs>
endfunction

function! EchoFuncStop()
    iunmap      <buffer>    (
    iunmap      <buffer>    <m-n>
    iunmap      <buffer>    <m-b>
endfunction

function! s:RestoreSettings()
    if s:bShowMode
        set showmode
    endif
    exec "set cmdheight=".s:CmdHeight
endfunction



if has("autocmd") && !exists("au_restoremode_loaded")
    let au_restoremode_loaded=1
    autocmd InsertLeave * call s:RestoreSettings()
endif
