"==================================================
" File:         echofunc.vim
" Brief:        Echo the function declaration in
"               the command line for C/C++.
" Author:       Mingbai <mbbill AT gmail DOT com>
" Last Change: 2007-07-31 17:24:24
" Version:      1.4
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
" Thanks:       edyfox
"
"==================================================

let s:res=[]
let s:count=1
let s:bShowMode=&showmode
let s:CmdHeight=&cmdheight
autocmd BufReadPost * call EchoFuncStart()
menu        &Tools.Echo\ Function\ Start          :call EchoFuncStart()<CR>
menu        &Tools.Echo\ Function\ Stop           :call EchoFuncStop()<CR>

if has("balloon_eval")
    autocmd BufReadPost * call BalloonDeclarationStart()
    menu        &Tools.Balloon\ Declaration\ Start          :call BalloonDeclarationStart()<CR>
    menu        &Tools.Balloon\ Declaration\ Stop           :call BalloonDeclarationStop()<CR>
endif

function! s:EchoFuncDisplay()
    if len(s:res) == 0
        return
    endif
    set noshowmode
    let wincolumn=&columns
    if len(s:res[s:count-1]) > (wincolumn-12)
        set cmdheight=2
    else
        set cmdheight=1
    endif
    echohl Type | echo s:res[s:count-1] | echohl None
endfunction

function! s:GetFunctions(fun, fn_only)
    let s:res=[]
    let ftags=taglist(a:fun)
    if (type(ftags)==type(0) || ((type(ftags)==type([])) && ftags==[]))
"        \ && a:fn_only
        return
    endif
    let fil_tag=[]
    for i in ftags
        if has_key(i,'kind') && has_key(i,'name') && has_key(i,'signature')
            if (i.kind=='p' || i.kind=='f' || a:fn_only == 0) && i.name==a:fun " p is declare, f is defination
                let fil_tag+=[i]
            endif
        else
            if a:fn_only == 0 && i.name == a:fun
                let fil_tag+=[i]
            endif
        endif
    endfor
    if fil_tag==[]
        return
    endif
    let s:count=1
    for i in fil_tag
        if has_key(i,'kind') && has_key(i,'name') && has_key(i,'signature')
            let name=substitute(i.cmd[2:],i.name.'.*','','g').i.name.i.signature
        else
            let name=substitute(i.cmd[2:],i.name.'.*','','g').i.name
        endif
        let s:res+=[name.' ('.(index(fil_tag,i)+1).'/'.len(fil_tag).') '.i.filename]
    endfor
endfunction

function! EchoFunc()
    let fun=substitute(getline('.')[:(col('.'))],'\zs.*\W\ze\w*$','','g') " get function name
    call s:GetFunctions(fun, 1)
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
"    inoremap    <silent>    <buffer>    <leader>n   <c-r>=EchoFuncN()<cr><bs>
"    inoremap    <silent>    <buffer>    <leader>p   <c-r>=EchoFuncP()<cr><bs>
endfunction

function! EchoFuncStop()
    iunmap      <buffer>    (
    iunmap      <buffer>    <leader>n
    iunmap      <buffer>    <leader>p
endfunction

function! s:RestoreSettings()
    if s:bShowMode
        set showmode
    endif
    exec "set cmdheight=".s:CmdHeight
endfunction

function! BalloonDeclaration()
    call s:GetFunctions(v:beval_text, 0)
    let result = ""
    for item in s:res
        let result = result . item . "\n"
    endfor
    return strpart(result, 0, len(result) - 1)
endfunction

function! BalloonDeclarationStart()
    set ballooneval
    set balloonexpr=BalloonDeclaration()
endfunction

function! BalloonDeclarationStop()
    set balloonexpr=
    set noballooneval
endfunction

if has("autocmd") && !exists("au_restoremode_loaded")
    let au_restoremode_loaded=1
    autocmd InsertLeave * call s:RestoreSettings()
endif
