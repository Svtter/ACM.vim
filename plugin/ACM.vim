" ACM / icpc plugin for ACMer
" Last Change: 
" Maintainer: svtter <svtter@qq.com>
" License: 
"
"
"
" Judge OS
let s:iswindows = 0
let s:islinux = 0
if(has("win32") || has("win64") || has("win95") || has("win16"))
    let s:iswindows = 1
else
    let s:islinux = 1
endif

" Gvim or Terminal
if has("gui_running")
    let s:isGUI = 1
else
    let s:isGUI = 0
endif




" add to command, make it available to change
let s:functionlist = ['Run', 'Debug', 'Tidy', 'TitleDet', 'UpdateTitle', 'Link', 'Compile']

" if !exists(":Run")
  " command -nargs=?  Run call s:Run(<f-args>)
" endif


" -----------------------------------------------------------------------------
" var setting
" -----------------------------------------------------------------------------
"
" use to control the templete file and author name
let g:acm_templete_file = ""
let g:author_name = ""

" Control auto-indent
if !exists("g:enable_save_to_indent") 
    let g:enable_save_to_indent = 1
endif

" terminal
if !exists("g:ACM_terminal")
    let g:ACM_terminal = "gnome-terminal"
endif



" ACM:
" Control the ACM template
augroup ACM
    " enable to source
    autocmd!
    " read template
    autocmd FileType c,cpp 0r ~/github/ACM_templete/init.cpp
    autocmd FileType c,cpp setlocal textwidth=80 formatoptions+=t  

    " auto indent
    if g:enable_save_to_indent
        autocmd BufWritePre *.cpp :call Tidy()
        autocmd BufWritePre *.c :call Tidy()
    endif
augroup END



" -----------------------------------------------------------------------------
"  < 单文件编译、连接、运行配置 >
" -----------------------------------------------------------------------------
" 以下只做了 C、C++ 的单文件配置，其它语言可以参考以下配置增加

" F9 一键保存、编译、连接存并运行
noremap <F9> :call Run()<CR>
inoremap <F9> <ESC>:call Run()<CR>

" Ctrl + F9 一键保存并编译
noremap <c-F9> :call Compile()<CR>
inoremap <c-F9> <ESC>:call Compile()<CR>

" Ctrl + F10 一键保存并连接
noremap <c-F10> :call Link()<CR>
inoremap <c-F10> <ESC>:call Link()<CR>

" F8 编译调试（仅限于单文件)
noremap <F8> :call Debug()<CR>
inoremap <F8> <ESC>:call Debug()<CR>

" 仅运行，运行过后删除
noremap <F6> :call TempRun()<CR>
inoremap <F6> <ESC>:call TempRun()<CR>

let s:LastShellReturn_C = 0
let s:LastShellReturn_L = 0
let s:ShowWarning = 1
let s:Obj_Extension = '.o'
let s:Exe_Extension = '.exe'
let s:Sou_Error = 0

" able to change
" 编译选项 C语言
let s:windows_CFlags = 'gcc\ -fexec-charset=gbk\ -Wall\ -g\ -lm\ -O0\ -c\ %\ -o\ %<.o'
let s:linux_CFlags = 'gcc\ -Wall\ -g\ -lm\ -O0\ -c\ %\ -o\ %<.o'

" 编译选项 C++
let s:windows_CPPFlags = 'g++\ -fexec-charset=gbk\ -Wall\ -DDEBUG\ -g\ -O0\ -c\ %\ -o\ %<.o'
let s:linux_CPPFlags = 'g++\ -Wall\ -DDEBUG\ -g\ -O0\ -c\ %\ -o\ %<.o'

function! Compile()
    exe ":ccl"
    exe ":update"
    let s:Sou_Error = 0
    let s:LastShellReturn_C = 0
    let Sou = expand("%:p")
    let v:statusmsg = ''
    if expand("%:e") == "c" || expand("%:e") == "cpp" || expand("%:e") == "cxx"
        let Obj = expand("%:p:r").s:Obj_Extension
        let Obj_Name = expand("%:p:t:r").s:Obj_Extension
        if !filereadable(Obj) || (filereadable(Obj) && (getftime(Obj) < getftime(Sou)))
            redraw!
            if expand("%:e") == "c"
                if s:iswindows
                    exe ":setlocal makeprg=".s:windows_CFlags
                else
                    exe ":setlocal makeprg=".s:linux_CFlags
                endif
                echohl WarningMsg | echo " compiling..."
                silent make
            elseif expand("%:e") == "cpp" || expand("%:e") == "cxx"
                if s:iswindows
                    exe ":setlocal makeprg=".s:windows_CPPFlags
                else
                    exe ":setlocal makeprg=".s:linux_CPPFlags
                endif
                echohl WarningMsg | echo " compiling..."
                silent make
            endif
            redraw!
            if v:shell_error != 0
                let s:LastShellReturn_C = v:shell_error
            endif
            if s:iswindows
                if s:LastShellReturn_C != 0
                    exe ":bo cope"
                    echohl WarningMsg | echo " compilation failed"
                else
                    if s:ShowWarning
                        exe ":bo cw"
                    endif
                    echohl WarningMsg | echo " compilation successful"
                endif
            else
                if empty(v:statusmsg)
                    echohl WarningMsg | echo " compilation successful"
                else
                    exe ":bo cope"
                endif
            endif
        else
            echohl WarningMsg | echo ""Obj_Name"is up to date"
        endif
    else
        let s:Sou_Error = 1
        echohl WarningMsg | echo " please choose the correct source file"
    endif
    exe ":setlocal makeprg=make"
endfunc

function! Link()
    call Compile()
    if s:Sou_Error || s:LastShellReturn_C != 0
        return
    endif
    if expand("%:e") == "c" || expand("%:e") == "cpp" || expand("%:e") == "cxx"
        let s:LastShellReturn_L = 0
        let Sou = expand("%:p")
        let Obj = expand("%:p:r").s:Obj_Extension
        if s:iswindows
            let Exe = expand("%:p:r").s:Exe_Extension
            let Exe_Name = expand("%:p:t:r").s:Exe_Extension
        else
            let Exe = expand("%:p:r")
            let Exe_Name = expand("%:p:t:r")
        endif
        let v:statusmsg = ''
        if filereadable(Obj) && (getftime(Obj) >= getftime(Sou))
            redraw!
            if !executable(Exe) || (executable(Exe) && getftime(Exe) < getftime(Obj))
                if expand("%:e") == "c"
                    setlocal makeprg=gcc\ -lm\ -o\ %<\ %<.o
                    echohl WarningMsg | echo " linking..."
                    silent make
                elseif expand("%:e") == "cpp" || expand("%:e") == "cxx"
                    setlocal makeprg=g++\ -o\ %<\ %<.o
                    echohl WarningMsg | echo " linking..."
                    silent make
                endif
                redraw!
                if v:shell_error != 0
                    let s:LastShellReturn_L = v:shell_error
                endif
                if s:iswindows
                    if s:LastShellReturn_L != 0
                        exe ":bo cope"
                        echohl WarningMsg | echo " linking failed"
                    else
                        if s:ShowWarning
                            exe ":bo cw"
                        endif
                        echohl WarningMsg | echo " linking successful"
                    endif
                else
                    if empty(v:statusmsg)
                        echohl WarningMsg | echo " linking successful"
                    else
                        exe ":bo cope"
                    endif
                endif
            else
                echohl WarningMsg | echo ""Exe_Name"is up to date"
            endif
        endif
        setlocal makeprg=make
    endif
endfunc

function! Run()
    " confirm directory
    let s:pwd = expand("%:p:h")
    let s:ShowWarning = 0
    call Link()
    let s:ShowWarning = 1
    if s:Sou_Error || s:LastShellReturn_C != 0 || s:LastShellReturn_L != 0
        return
    endif
    let Sou = expand("%:p")
    if expand("%:e") == "c" || expand("%:e") == "cpp" || expand("%:e") == "cxx"
        let Obj = expand("%:p:r").s:Obj_Extension
        if s:iswindows
            let Exe = expand("%:p:r").s:Exe_Extension
        else
            let Exe = expand("%:p:r")
        endif
        if executable(Exe) && getftime(Exe) >= getftime(Obj) && getftime(Obj) >= getftime(Sou)
            redraw!
            echohl WarningMsg | echo " running..."
            if s:iswindows
                exe ":!%<.exe"
            else
                if s:isGUI
                    " exe ":!gnome-terminal -x bash -c ' cd " . s:pwd . ";time ./%<; echo; echo 请按 Enter 键继续; read'"
                    exe ":!". g:ACM_terminal . " -x bash -c ' cd " . s:pwd . ";time ./%<; echo; echo 请按 Enter 键继续; read'"
                else
                    exe ":!clear; ./%<"
                endif
            endif
            redraw!
            echohl WarningMsg | echo " running finish"
        endif
    endif
endfunc

function! Debug()
    " confirm directory
    let s:pwd = expand("%:p:h")
    let s:ShowWarning = 0
    call Link()
    let s:ShowWarning = 1
    if s:Sou_Error || s:LastShellReturn_C != 0 || s:LastShellReturn_L != 0
        return
    endif
    let Sou = expand("%:p")
    if expand("%:e") == "c" || expand("%:e") == "cpp" || expand("%:e") == "cxx"
        let Obj = expand("%:p:r").s:Obj_Extension
        if s:iswindows
            let Exe = expand("%:p:r").s:Exe_Extension
        else
            let Exe = expand("%:p:r")
        endif
        if executable(Exe) && getftime(Exe) >= getftime(Obj) && getftime(Obj) >= getftime(Sou)
            redraw!
            echohl WarningMsg | echo " running..."
            if s:iswindows
                exe ":!gdb %<.exe"
            else
                if s:isGUI
                    exe ":!". g:ACM_terminal . " -x bash -c ' cd " . s:pwd . ";gdb ./%<; echo; echo 请按 Enter 键继续; read'"
                else
                    exe ":!clear; ./%<"
                endif
            endif
            redraw!
            echohl WarningMsg | echo " running finish"
        endif
    endif
endfunc

" arrange code
function! Tidy()
    let s:linenum = line(".")
    execute ":normal gg=G"
    execute ":".s:linenum
    execute ":normal zz"
endfunction

function! TempRun()
    call Run()
    exe "!rm %<.o %<"
endfunction

" -----------------------------------------------------------------------------
" < 作者名 插入设置>
" -----------------------------------------------------------------------------

"进行版权声明的设置
"添加或更新头
noremap <F4> :call TitleDet()<cr>'s
function! AddTitle()
    call append(0,"/*=============================================================================")
    call append(1,"#")
    call append(2,"# Author: svtter - svtter@qq.com")
    call append(3,"#")
    call append(4,"# QQ : 57180160")
    call append(5,"#")
    call append(6,"# Last modified: ".strftime("%Y-%m-%d %H:%M"))
    call append(7,"#")
    call append(8,"# Filename: ".expand("%:t"))
    call append(9,"#")
    call append(10,"# Description: ")
    call append(11,"#")
    call append(12,"=============================================================================*/")
    echohl WarningMsg | echo "Successful in adding the copyright." | echohl None
endf

"更新最近修改时间和文件名
function! UpdateTitle()
    normal m'
    execute '/# *Last modified:/s@:.*$@\=strftime(":\t%Y-%m-%d %H:%M")@'
    normal ''
    normal mk
    execute '/# *Filename:/s@:.*$@\=":\t\t".expand("%:t")@'
    execute "noh"
    normal 'k
    echohl WarningMsg | echo "Successful in updating the copy right." | echohl None
endfunction

"判断前10行代码里面，是否有Last modified这个单词，
"如果没有的话，代表没有添加过作者信息，需要新添加；
"如果有的话，那么只需要更新即可
function! TitleDet()
    let n=1
    "默认为添加
    while n < 10
        let line = getline(n)
        if line =~ '^\#\s*\S*Last\smodified:\S*.*$'
            call UpdateTitle()
            return
        endif
        let n = n + 1
    endwhile
    call AddTitle()
endfunction
