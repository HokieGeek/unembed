if exists("g:autoloaded_unembed") || v:version < 700
    finish
endif
let g:autoloaded_unembed = 1

function! unembed#Unembed(line1, line2, ...)
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

    let l:unembedId = "id"
    let b:unembed__regions = { l:unembedId : [a:line1, a:line2] } " FIXME: pick a good id scheme
    let l:snippet = getline(a:line1, a:line2)

    " Create the buffer for the unembedded snippet
    enew
    let b:unembed__id = l:unembedId
    let b:unembed__filename = tempname()
    execute "silent file ".b:unembed__filename
    execute "setlocal filetype=".l:filetype

    silent! put =l:snippet
    0d_
    write

    execute "autocmd BufWritePost <buffer> call unembed#UpdateParentBuffer('".l:originalBuffer."')"
endfunction

function! unembed#UpdateParentBuffer(buffer)
    let l:currBuf = bufnr("%")
    let l:unembeddedId = b:unembed__id
    let l:unembeddedFile = b:unembed__filename
    let l:unembeddedNumLines = line("$")

    " Switch to the parent buffer
    execute "buffer ".a:buffer
    let l:winview = winsaveview()

    " Delete the old region and insert the update
    let l:region = get(b:unembed__regions, l:unembeddedId)
    execute join(l:region, ",")."d"
    let l:insertionLine = l:region[0] - 1
    execute "silent! ".l:insertionLine."read ".l:unembeddedFile
    write
    call winrestview(l:winview)

    " Update the new region dimensions
    let l:newRegionEnd = l:region[0] + l:unembeddedNumLines - 1
    let b:unembed__regions[l:unembeddedId] = [l:region[0], l:newRegionEnd]

    " Go back to the unembedded
    execute "buffer ".l:currBuf
endfunction
