%include "include/std.asm"
%include "out/bss.asm"
%include "out/data.asm"
%include "out/func.asm"
segment .text
global _start
ul_main:
enter
push string_64
call ul_strlen
call ul_print
return
_start:
call ul_main
exit 0
