; --------------------------------------------------------------
; Mersenne Twister in NASM
; 
; A pseudo random number generator (PRNG)
; See http://en.wikipedia.org/wiki/Mersenne_Twister
;
; Chris Goldmsith
; 29.03.2015
;
; Usage:
; First set the seed by calling either _init_generator
; or _seed_generator. 
; Each subsequent call to _extract_number returns a
; pseudo random 32 bit integer in eax.
; 
; _init_generator: set the seed based on cpu cycles (rdtsc).
; _seed_generator: set the seed to value passed in eax.
; _extract_number: 32 bit pseudo random integer returned in eax.
; --------------------------------------------------------------

STATE equ 624			; State table size = 624 32 integers

NUMGEN1 equ 0x7FFFFFFF	; for use in _generate_numbers
NUMGEN2 equ 0x80000000	; for use in _generate_numbers
NUMGEN3 equ 0x9908b0df	; for use in _generate_numbers
EXTRACT1 equ 0x9d2c5680	; for use in _extract_numbers
EXTRACT2 equ 0xefc60000 ; for use in _extract_numbers

section .data

initmul dd 0x6c078965	; for use in _init_generator

section .bss

mtstate resd STATE		; State table
mtindex resd 1			; Current index of mtstate

; --------------------------------------------------------------

section .text

; Initialize the generator
; seed is generated from cpu cycles since last reset
global _init_generator
_init_generator:
	push		eax
	push		edx

	rdtsc		; return stime stamp counter
				; returns cpu cycles since reset in eax and edx

	call		_seed_generator		; initialise PRNG
									; seed in eax
	pop			edx
	pop			eax
	ret

; Initialize the generator from a seed
; seed passed in eax
global _seed_generator
_seed_generator:
	pusha

	mov	dword	[mtindex], 0		; initalise index
	mov			[mtstate], eax		; first value = seed

	mov			ebx, mtstate		; state table
	mov			esi, 0				; state table index
	mov			ecx, 1				; index

.igloop:
	mov			eax, [ebx + esi]	; MT[i - 1]	
	mov			edx, eax			; MT[i - 1]
	shr			eax, 30				; MT[i - 1] right shift 30 bits
	xor			eax, edx			; XOR the two
	mul	dword	[initmul]			; multiple eax by this number
	add			eax, ecx			; add the index
	
	add			esi, 4				; -> MT[i]
	mov			[ebx + esi], eax	; store in MT[i]

	inc			ecx					; increase index
	cmp			ecx, STATE
	jl			.igloop

	popa
	ret

global _extract_number
; Extract a tempered pseudorandom number based on the mtindex-th value,
; calling generate_numbers every 624 numbers
; - pseudo random number returned in eax
_extract_number:
	push		ebx					; save regs
	push		ecx					; (not eax!)
	push		edx
	push		edi
	push		esi

	mov			esi, [mtindex]		; state table index
	shl			esi, 2				; index * 4
	cmp			esi, 0				; need to generate numbers?
	jne			.skipload
	call		_generate_numbers
	mov			esi, 0				; restore esi

.skipload:
	mov			ebx, mtstate		; state table
	mov			eax, [ebx + esi]	; MT[index] = 'y'
	mov			edx, eax			; copy of 'y'
	shr			edx, 11				; 'y' right shift 11 bits
	xor			eax, edx			; 'y' xor ('y' right shift 11 bits)

	mov			edx, eax			; copy of 'y'
	shl			edx, 7				; 'y' left shift 7 bits
	and			edx, EXTRACT1		; <above> and 0x9d2c5680
	xor			eax, edx			; 'y' xor <above>
	
	mov			edx, eax			; copy of 'y'
	shl			edx, 15				; 'y' left shift 15 bits
	and			edx, EXTRACT2		; <above> and 0xefc60000
	xor			eax, edx			; 'y' xor <above>

	mov			edx, eax			; copy of 'y'
	shr			edx, 18				; 'y' right shift 18 bits
	xor			eax, edx			; 'y' xor <above>
	; result is in eax

	mov			esi, [mtindex]		; increment the index for next time
	inc			esi
	cmp			esi, STATE			; roll over?
	jl			.skipidx
	mov			esi, 0
.skipidx:
	mov			[mtindex], esi		; save new index

	pop			esi					; restore regs
	pop			edi					; (not eax!)
	pop			edx
	pop			ecx
	pop			ebx
	ret

; Generate an array of 624 untempered numbers
; - internal
_generate_numbers:
	mov			ebx, mtstate		; state table
	mov			esi, 0				; state table index
	mov			ecx, STATE			; counter

.gnloop:
	mov			edi, esi
	add			edi, 4				; i + 1
	cmp			edi, STATE * 4
	jne			.skipmod1
	mov			edi, 0				; (i + 1) % 624
.skipmod1:
	mov			eax, [ebx + edi]	; MT[i + 1]
	and			eax, NUMGEN1		; MT[i + 1] and 0x7FFFFFFF
	mov			edx, [ebx + esi]	; MT[i]
	and			edx, NUMGEN2		; MT[i] and 0x80000000
	add			eax, edx			; add the two = 'y'
	push		eax					; save 'y'
	
	mov			edi, esi
	add			edi, 1588			; i + 397 (397 x 4 = 1588)
	cmp			edi, STATE * 4
	jl			.skipmod2
	sub			edi, STATE * 4		; (i + 397) % 624
 .skipmod2:
	mov			edx, [ebx + edi]	; MT[i + 397]
	shr			eax, 1				; 'y' right shift 1 bit
	xor			edx, eax			; MT[i + 397] xor ('y' right shift 1)

	pop			eax					; 'y'
	and			eax, 1				; is 'y' odd?
	cmp			eax, 0
	je			.even	
	xor			edx, NUMGEN3		; xor with 0x9908b0df
.even:
	mov			[ebx + esi], edx	; store result

	add			esi, 4				; -> MT[i]
	loop		.gnloop

	ret
