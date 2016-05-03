if exists("g:autoloaded_unembed") || v:version < 700
    finish
endif
let g:autoloaded_unembed = 1

function! unembed#Unembed(line1, line2, ...)
    let l:unembed_id = "id"
    let l:original_buffer = bufname("%")
    let l:filetype = ""
    if a:0 > 0
        let l:filetype = a:1
    else
        call inputsave()
        let l:filetype = input("Specify filetype: ")
        call inputrestore()
    endif
    let b:unembed__regions = { l:unembed_id : [a:line1, a:line2] } " FIXME: pick a good id scheme
    silent! execute a:line1.",".a:line2."yank u"

    enew
    let b:unembed__filename = tempname()
    execute "silent file ".b:unembed__filename
    " execute "silent file unembedded_".l:original_buffer
    execute "setlocal filetype=".l:filetype

    silent! put u
    0d_
    write

    execute "autocmd BufWritePost <buffer> call unembed#UpdateParentBuffer('".l:original_buffer."', '".l:unembed_id."', '".b:unembed__filename."')"
    " execute "autocmd BufDelete <buffer> call delete('".b:unembed__filename."')"
endfunction

function! unembed#UpdateParentBuffer(buffer, unembeddedId, unembeddedFile)
    " echom "unembed#UpdateParentBuffer(".a:buffer.", ".a:unembeddedId.")"
    let l:currBuf = bufnr("%")

    execute "buffer ".a:buffer
    " TODO: save view and then restore it
    let l:region = get(b:unembed__regions, a:unembeddedId)
    " echom a:unembeddedId.": ".join(l:region, " to ")

    " Do the deed
    execute join(l:region, ",")."d"
    let l:insertionLine = l:region[0] - 1
    execute "silent! ".l:insertionLine."read ".a:unembeddedFile

    " Go back to the unembedded
    execute "buffer ".l:currBuf
endfunction
