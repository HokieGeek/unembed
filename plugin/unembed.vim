if exists("g:loaded_unembed") || v:version < 700
    finish
endif
let g:loaded_unembed = 1

command! -range -nargs=? Unembed :call unembed#Unembed(<line1>, <line2>, <f-args>)
