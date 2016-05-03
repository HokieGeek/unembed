if exists("g:loaded_unembed") || v:version < 700
    finish
endif
let g:loaded_unembed = 1

command! Unembed :call unembed#Unembed()
