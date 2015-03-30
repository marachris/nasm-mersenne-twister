; --------------------------------------------------------------
; Test Program for Mersenne Twister - mtwister.asm
; 
; - on Linux -
;
; Chris Goldmsith
; 29.03.2015
; --------------------------------------------------------------

extern _init_generator, _extract_number

SYS_EXIT   equ 1
SYS_WRITE  equ 4
STDOUT equ 1

section .text
global _start
_start:
	call        _init_generator     ; seed the PRNG

	mov         ecx, 6              ; get 6 test numbers
.prngloop:
	call        _extract_number     ; get random 32 bit int in eax
	call        _printintdec        ; print integer in eax
	loop        .prngloop

.exit:
	mov         ebx, 0
	mov         eax, SYS_EXIT
	int         0x80

; print a 32 bit integer, as a decimal
; the integerer is passed in eax
; (the ascii decimal equivalent is written to 'decnum')
_printintdec:
	push        ecx
	mov         ecx, 10         ; 10 decimal digits
	mov         ebx, decnum + 9 ; store ascii equivalent here
.loop:
	push        ecx             ; save loop counter
	mov         edx, 0
	mov         ecx, 10         ; divide eax by 10
	div         ecx             ; ...remainder is in edx
	add         dl, '0'         ; convert remainder to ascii
	mov byte    [ebx], dl       ; store ascii digit
	dec         ebx
	pop         ecx             ; restore loop counter
	loop        .loop

; print the decimal number in 'decnum'
	mov     edx, 11
	mov     ecx, decnum
	mov     ebx, STDOUT
	mov     eax, SYS_WRITE
	int     0x80
	pop     ecx
	ret

section .data
decnum db '0000000000', 10	  ; 32 bit integer, as ascii
