if exists("g:autoloaded_unembed") || v:version < 700
    finish
endif
let g:autoloaded_unembed = 1

function! unembed#UnembeddedId(...) " {{{
    " FIXME: pick a good id scheme
    " Would be nice if this was a hash of the region lines which I could use
    " to determine if the dictionary entry applies to other regions
    return "id"
endfunction " }}}

function! unembed#IsUnembedded(...) " {{{
    if a:0 > 0 && exists("b:unembedded")
        let l:line1 = a:1
        let l:line2 = a:1
        if a:0 > 1
            let l:line2 = a:2
        endif
        for unembed in b:unembedded
            if l:line1 >= unembed["region"][0] && l:line2 <= unembed["region"][1]
                return 1
            endif
        endfor
    endif
    return 0
endfunction " }}}

function! unembed#Unembed(line1, line2, ...) " {{{
    let l:originalBuffer = bufname("%")

    " Determine the filetype
    let l:filetype = ""
    if a:0 > 0
        let l:filetype = a:1
    else
        call inputsave()
        let l:filetype = input("Specify filetype: ")
        call inputrestore()
    endif

    if !exists("b:unembedded")
        let b:unembedded = {}
    endif

    let l:unembedId = unembed#UnembeddedId(a:line1, a:line2)
    let l:unembeddedFilename = expand("%").".".len(b:unembedded)
    if len(l:filetype) > 0
        let l:unembeddedFilename .= ".".l:filetype
    endif

    let b:unembedded[l:unembedId] = { "region" : [a:line1, a:line2],
                                    \ "filename": l:unembeddedFilename }
    let l:snippet = getline(a:line1, a:line2)

    " Create hand-dandy command to switch to the 
    command -buffer -nargs=0 Unembedded :call unembed#GoTo()

    " Create the buffer for the unembedded snippet
    execute "edit ".l:unembeddedFilename
    let b:unembed__id = l:unembedId
    let b:unembed__parent = l:originalBuffer
    execute "setlocal filetype=".l:filetype

    silent! put =l:snippet
    0d_
    silent! write

    augroup Unembed
        autocmd!
        autocmd BufWritePost <buffer> call unembed#UpdateParentBuffer()
        execute "autocmd BufDelete <buffer> call unembed#RemoveUnembedded('".b:unembed__id."', '".b:unembed__parent."')"
    augroup END
endfunction " }}}

function! unembed#UpdateParentBuffer() " {{{
    let l:currBuf = bufnr("%")
    let l:unembeddedId = b:unembed__id
    let l:unembeddedFile = bufname("%")
    let l:unembeddedNumLines = line("$")

    " Switch to the parent buffer
    execute "buffer ".b:unembed__parent
    let l:winview = winsaveview()

    " Delete the old region
    let l:unembedded = get(b:unembedded, l:unembeddedId)
    let l:region = get(l:unembedded, "region")
    execute "silent! ".join(l:region, ",")."d"

    " and insert the update
    let l:insertionLine = l:region[0] - 1
    execute "silent! ".l:insertionLine."read ".l:unembeddedFile
    silent! write
    call winrestview(l:winview)

    " Update the new region dimensions
    let l:newRegionEnd = l:region[0] + l:unembeddedNumLines - 1
    let l:unembedded["region"] = [l:region[0], l:newRegionEnd]
    let b:unembedded[l:unembeddedId] = l:unembedded

    " Go back to the unembedded
    execute "buffer ".l:currBuf
endfunction " }}}

function! unembed#RemoveUnembedded(id, parent) " {{{
    execute "call delete('".bufname("%")."')"
    execute "buffer ".a:parent
    call remove(b:unembedded, a:id)
    if empty(b:unembedded)
        unlet b:unembedded
    endif
    delcommand Unembedded
endfunction " }}}

function! unembed#GoTo() " {{{
    let l:id = unembed#UnembeddedId(line("."))
    if exists("b:unembedded") && has_key(b:unembedded, l:id)
        execute "buffer ".b:unembedded[l:id]["filename"]
    endif
endfunction " }}}

" vim: set foldmethod=marker formatoptions-=tc:
