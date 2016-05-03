if exists("g:autoloaded_unembed") || v:version < 700
    finish
endif
let g:autoloaded_unembed = 1

function! unembed#Unembed(line1, line2, ...)
    let l:filetype = ""
    if a:0 > 0
        let l:filetype = a:1
    else
        call inputsave()
        let l:filetype = input("Specify filetype: ")
        call inputrestore()
    endif
    let b:unembed__regions = { "id" : [a:line1, a:line2] } " FIXME: pick a good id scheme
    silent! execute a:line1.",".a:line2."yank u"
    enew
    silent! put u
    0d_
    execute "setlocal filetype=".l:filetype
endfunction
