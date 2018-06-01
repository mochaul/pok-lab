;====================================================================
; Processor		: ATmega8515
; Compiler		: AVRASM
;====================================================================

;====================================================================
; DEFINITIONS
;====================================================================

.include "m8515def.inc"
.def temp = r16 ; temporary register
.def led_data = r17
.def counter = r20 ; counter register
.def EW = r23 ; for PORTA
.def PB = r24 ; for PORTB
.def A  = r25 ; message temporary data

;====================================================================
; RESET and INTERRUPT VECTORS
;====================================================================

.org $00
rjmp MAIN
.org $01
rjmp ext_int0
.org $02
rjmp ext_int1

;====================================================================
; CODE SEGMENT
;====================================================================

MAIN:

INIT_STACK:
	ldi temp, low(RAMEND)
	ldi temp, high(RAMEND)
	out SPH, temp

rcall INIT_LCD_MAIN

INIT_LED:
	ser temp ; load $FF to temp
	out DDRC,temp ; Set PORTC to output

INIT_INTERRUPT:
	ldi temp,0b00001010
	out MCUCR,temp
	ldi temp,0b11000000
	out GICR,temp
	sei

INIT_COUNTER:
	ldi counter, 0 ; init counter

LED_LOOP:
	ldi led_data,0x00
	out PORTC,led_data ; Update LEDS
	rcall CHOOSE_DELAY
	ldi led_data,0x01
	out PORTC,led_data ; Update LEDS
	rcall CHOOSE_DELAY
	ldi led_data,0x02
	out PORTC,led_data ; Update LEDS
	rcall CHOOSE_DELAY
	ldi led_data,0x04
	out PORTC,led_data ; Update LEDS
	rcall CHOOSE_DELAY
	ldi led_data,0x08
	out PORTC,led_data ; Update LEDS
	rcall CHOOSE_DELAY
	ldi led_data,0x10
	out PORTC,led_data ; Update LEDS
	rcall CHOOSE_DELAY
	ldi led_data,0x20
	out PORTC,led_data ; Update LEDS
	rcall CHOOSE_DELAY
	ldi led_data,0x40
	out PORTC,led_data ; Update LEDS
	rcall CHOOSE_DELAY
	ldi led_data,0x80
	out PORTC,led_data ; Update LEDS
	rcall CHOOSE_DELAY
	rjmp LED_LOOP

ext_int0:
	rcall CLEAR_LCD
	cpi led_data, $04
	breq SHOW_WIN
	cpi led_data, $20
	breq SHOW_WIN
	
	ldi ZH,high(2*kalah) ; Load high part of byte address into ZH
	ldi ZL,low(2*kalah) ; Load low part of byte address into ZL
	rcall LOADBYTE
	reti

	SHOW_WIN:
		ldi ZH,high(2*menang) ; Load high part of byte address into ZH
		ldi ZL,low(2*menang) ; Load low part of byte address into ZL
		rcall LOADBYTE
		reti

ext_int1:
	inc counter
	cpi counter, 3
	brne EXIT_INT1
	ldi counter, 0
	EXIT_INT1:
		reti

CHOOSE_DELAY:

	cpi counter, 0
	breq TO_DELAY00 ; jump to delay_00
	cpi counter, 1
	breq TO_DELAY01 ; jump to delay_01
	cpi counter, 2
	breq TO_DELAY02 ; jump to delay_02

	TO_DELAY00:
		rcall DELAY_00
		ret
		
	TO_DELAY01:
		rcall DELAY_01
		ret
		
	TO_DELAY02:
		rcall DELAY_02
		ret


DELAY_00:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; Delay 4 000 cycles
	; 500us at 8.0 MHz

	    ldi  r18, 6
	    ldi  r19, 49
	L0: dec  r19
	    brne L0
	    dec  r18
	    brne L0
	ret


DELAY_01:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; DELAY_CONTROL 40 000 cycles
	; 5ms at 8.0 MHz

	    ldi  r18, 52
	    ldi  r19, 242
	L1: dec  r19
	    brne L1
	    dec  r18
	    brne L1
	    nop
	ret

DELAY_02:
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 160 000 cycles
; 20ms at 8.0 MHz

	    ldi  r18, 208
	    ldi  r19, 202
	L2: dec  r19
	    brne L2
	    dec  r18
	    brne L2
	    nop
		ret

INIT_LCD_MAIN:
	rcall INIT_LCD

	ser temp
	out DDRA,temp ; Set port A as output
	out DDRB,temp ; Set port B as output

	ret

INIT_LCD:
	cbi PORTA,1 ; CLR RS
	ldi PB,0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTB,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_01
	cbi PORTA,1 ; CLR RS
	ldi PB,$0E ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORTB,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_01
	rcall CLEAR_LCD ; CLEAR LCD
	cbi PORTA,1 ; CLR RS
	ldi PB,$06 ; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTB,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_01
	ret

CLEAR_LCD:
	cbi PORTA,1 ; CLR RS
	ldi PB,$01 ; MOV DATA,0x01
	out PORTB,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_01
	ret
	
LOADBYTE:
	lpm ; Load byte from program memory into r0

	tst r0 ; Check if we've reached the end of the message
	breq END_LCD ; If so, quit

	mov A, r0 ; Put the character onto Port B
	rcall WRITE_TEXT
	adiw ZL,1 ; Increase Z registers
	rjmp LOADBYTE

END_LCD:
	ret

WRITE_TEXT:
	sbi PORTA,1 ; SETB RS
	out PORTB, A
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_01
	ret

;====================================================================
; DATA
;====================================================================

menang:
.db "KAMU MENANG",0
kalah:
.db "KAMU KALAH", 0
