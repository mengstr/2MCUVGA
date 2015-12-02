; ***************************************************************************
; VGA_HSYNC.asm - Part of 2MCUVGA 
; ***************************************************************************
;
; The MIT License (MIT)
;
; Copyright (c) 2015 SmallRoomLabs
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; ***************************************************************************
;
;
;
;
; ** HORIZONTAL TIMING **
;		
;		Horizonal Dots         640     640     640        
;		Vertical Scan Lines    350     400     480
;		Horiz. Sync Polarity   POS     NEG     NEG
;		A (us)                 31.77   31.77   31.77     Scanline time
;		B (us)                 3.77    3.77    3.77      Sync pulse lenght 
;		C (us)                 1.89    1.89    1.89      Back porch
;		D (us)                 25.17   25.17   25.17     Active video time
;		E (us)                 0.94    0.94    0.94      Front porch
;		         ______________________          ________
;		________|        VIDEO         |________| VIDEO (next line)
;		    |-C-|----------D-----------|-E-|
;		__   ______________________________   ___________
;		  |_|                              |_|
;		  |B|
;		  |---------------A----------------|
;		
;		One Line - 800 pixels total per line
;
;		------------------------------------
;		8 pixels front porch 
;		96 pixels horizontal sync 
;		40 pixels back porch 
;		8 pixels left border 
;		640 pixels video 
;		8 pixels right border ;
;
;
;	+------------+ +-----------+
;   | 1 PA2/-Res +-+    VCC 20 |
;   | 2 PD0/RXD     CLK/PB7 19 |
;   | 3 PD1/TXD    MISO/PB6 18 |
;   | 4 PA1/XTAL2  MOSI/PB5 17 |
;   | 5 PA0/XTAL1  OC1B/PB4 16 |
;   | 6 PD2/INT0   OC1A/PB3 15 |
;   | 7 PD3/INT1   OC0A/PB2 14 |
;   | 8 PD4/T0     AIN1/PB1 13 |
;   | 9 PD5/T1     AIN0/PB0 12 |
;   | 10 GND        ICP/PD6 11 |
;   +--------------------------+
;           ATTINY2313
;
; Usage of Port B:
;   Bit 0: Output RAM Address bit 0
;       1: Output RAM Address bit 1 
;       2: Output RAM Address bit 2
;       3: Output RAM Address bit 3
;       4: Output RAM Address bit 4
;       5: Output RAM Address bit 5
;       6: Output HSYNC
;       7: Output Clock to next 2313

	
	.CSEG

; ************** Reset- and Interrupt-vectors ********
	.ORG $0000

	rjmp RESET					; Reset Handler
	rjmp Isr_INT0				; External Interrupt0 Handler
	rjmp Isr_INT1				; External Interrupt1 Handler
	rjmp Isr_TIM1_CAPT			; Timer1 Capture Handler
	rjmp Isr_TIM1_COMPA			; Timer1 CompareA Handler
	rjmp Isr_TIM1_OVF			; Timer1 Overflow Handler
	rjmp Isr_TIM0_OVF			; Timer0 Overflow Handler
	rjmp Isr_USART0_RXC			; USART0 RX Complete Handler
	rjmp Isr_USART0_DRE			; USART0,UDR Empty Handler
	rjmp Isr_USART0_TXC			; USART0 TX Complete Handler
	rjmp Isr_ANA_COMP			; Analog Comparator Handler
	rjmp Isr_PCINT				; Pin Change Interrupt
	rjmp Isr_TIMER1_COMPB		; Timer1 Compare B Handler
	rjmp Isr_TIMER0_COMPA		; Timer0 Compare A Handler
	rjmp Isr_TIMER0_COMPB		; Timer0 Compare B Handler
	rjmp Isr_USI_START			; USI Start Handler
	rjmp Isr_USI_OVERFLOW		; USI Overflow Handler
	rjmp Isr_EE_READY			; EEPROM Ready Handler
	rjmp Isr_WDT_OVERFLOW		; Watchdog Overflow Handler

; ************** Interrupt service routines ********

Isr_INT0:				; External Interrupt0 Handler
Isr_INT1:				; External Interrupt1 Handler
Isr_TIM1_CAPT:			; Timer1 Capture Handler
Isr_TIM1_COMPA:			; Timer1 CompareA Handler
Isr_TIM1_OVF:			; Timer1 Overflow Handler
Isr_TIM0_OVF:			; Timer0 Overflow Handler
Isr_USART0_RXC:			; USART0 RX Complete Handler
Isr_USART0_DRE:			; USART0,UDR Empty Handler
Isr_USART0_TXC:			; USART0 TX Complete Handler
Isr_ANA_COMP:			; Analog Comparator Handler
Isr_PCINT:				; Pin Change Interrupt
Isr_TIMER1_COMPB:		; Timer1 Compare B Handler
Isr_TIMER0_COMPA:		; Timer0 Compare A Handler
Isr_TIMER0_COMPB:		; Timer0 Compare B Handler
Isr_USI_START:			; USI Start Handler
Isr_USI_OVERFLOW:		; USI Overflow Handler
Isr_EE_READY:			; EEPROM Ready Handler
Isr_WDT_OVERFLOW:		; Watchdog Overflow Handler
	RETI


; ************** Code ********

RESET:
	CLI						; Disable interrupts

	LDI		R16,0x00		; Port A and D are all inputs
	OUT		DDRA,R16
	OUT		DDRD,R16
	LDI		R16,0xFF		; Enable pullups on Port A and D
	OUT		PORTA,R16
	OUT		PORTD,R16

	LDI		R16,0xFF		; Port B are all Outputs
	OUT		DDRB,R16

	LDI		R17,0x00		; Preloaded value (on) for HSYNC bit on Port A
	LDI		R18,0x00		; Preloaded value (off) for HSYNC bit on Port A

Loop:
	
	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; SYNC
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b00000000		; 
	OUT PORTB,R16

	LDI R16,0b01000000		; Video 0
	OUT PORTB,R16

	LDI R16,0b01000001		; Video 1
	OUT PORTB,R16

	LDI R16,0b01000010		; Video 2
	OUT PORTB,R16

	LDI R16,0b01000011		; Video 3
	OUT PORTB,R16

	LDI R16,0b01000100		; Video 4
	OUT PORTB,R16

	LDI R16,0b01000101		; Video 5
	OUT PORTB,R16

	LDI R16,0b01000110		; Video 6
	OUT PORTB,R16

	LDI R16,0b01000111		; Video 7
	OUT PORTB,R16

	LDI R16,0b01001000		; Video 8
	OUT PORTB,R16

	LDI R16,0b01001001		; Video 9
	OUT PORTB,R16

	LDI R16,0b01001010		; Video 10
	OUT PORTB,R16

	LDI R16,0b01001011		; Video 11
	OUT PORTB,R16

	LDI R16,0b01001100		; Video 12
	OUT PORTB,R16

	LDI R16,0b01001101		; Video 13
	OUT PORTB,R16

	LDI R16,0b01001110		; Video 14
	OUT PORTB,R16

	LDI R16,0b01001111		; Video 15
	OUT PORTB,R16

	LDI R16,0b01010000		; Video 16
	OUT PORTB,R16

	LDI R16,0b01010001		; Video 17
	OUT PORTB,R16

	LDI R16,0b01010010		; Video 18
	OUT PORTB,R16

	LDI R16,0b01010011		; Video 19
	OUT PORTB,R16

	LDI R16,0b01010100		; Video 20
	OUT PORTB,R16

	LDI R16,0b01010101		; Video 21
	OUT PORTB,R16

	LDI R16,0b01010110		; Video 22
	OUT PORTB,R16

	LDI R16,0b01010111		; Video 23
	OUT PORTB,R16

	LDI R16,0b11011000		; Video 24+CLOCK
	OUT PORTB,R16

	LDI R16,0b11011001		; Video 25+CLOCK
	OUT PORTB,R16

	LDI R16,0b11011010		; Video 26+CLOCK
	OUT PORTB,R16

	LDI R16,0b11011011		; Video 27+CLOCK
	OUT PORTB,R16

	LDI R16,0b11011100		; Video 28+CLOCK
	OUT PORTB,R16

	LDI R16,0b11011101		; Video 29+CLOCK
	OUT PORTB,R16

	LDI R16,0b11011110		; Video 30+CLOCK
	OUT PORTB,R16	

	LDI R16,0b11011111		; Video 31+CLOCK
	OUT PORTB,R16

	LDI R16,0b11100000		; Video 32+CLOCK
	OUT PORTB,R16

	LDI R16,0b11100001		; Video 33+CLOCK
	OUT PORTB,R16

	LDI R16,0b11100010		; Video 34+CLOCK
	OUT PORTB,R16

	LDI R16,0b11100011		; Video 35+CLOCK
	OUT PORTB,R16

	LDI R16,0b11100100		; Video 36+CLOCK
	OUT PORTB,R16

	LDI R16,0b11100101		; Video 37+CLOCK
	OUT PORTB,R16

	LDI R16,0b11100110		; Video 38+CLOCK
	OUT PORTB,R16

	LDI R16,0b11100111		; Video 39+CLOCK
	OUT PORTB,R16

	LDI R16,0b11101000		; Video 40+CLOCK
	OUT PORTB,R16

	LDI R16,0b11101001		; Video 41+CLOCK
	OUT PORTB,R16

	LDI R16,0b11101010		; Video 42+CLOCK
	OUT PORTB,R16

	LDI R16,0b11101011		; Video 43+CLOCK
	OUT PORTB,R16

	LDI R16,0b11101100		; Video 44+CLOCK
	OUT PORTB,R16

	LDI R16,0b11101101		; Video 45+CLOCK
	OUT PORTB,R16

	LDI R16,0b11101110		; Video 46+CLOCK
	OUT PORTB,R16

	LDI R16,0b11101111		; Video 47+CLOCK
	OUT PORTB,R16

	LDI R16,0b11110000		; Video 48+CLOCK
	OUT PORTB,R16

	LDI R16,0b11110001		; Video 49+CLOCK
	OUT PORTB,R16

	LDI R16,0b11110010		; Video 50+CLOCK
	OUT PORTB,R16

	LDI R16,0b11110011		; Video 51+CLOCK
	OUT PORTB,R16

	LDI R16,0b11110100		; Video 52+CLOCK
	OUT PORTB,R16

	LDI R16,0b11110101		; Video 53+CLOCK
	OUT PORTB,R16

	LDI R16,0b11110110		; Video 54+CLOCK
	OUT PORTB,R16

	LDI R16,0b11110111		; Video 55+CLOCK
	OUT PORTB,R16

	LDI R16,0b11111000		; Video 56+CLOCK
	OUT PORTB,R16

	LDI R16,0b11111001		; Video 57+CLOCK
	OUT PORTB,R16

	LDI R16,0b11111010		; Video 58+CLOCK
	OUT PORTB,R16

	LDI R16,0b11111011		; Video 59+CLOCK
	OUT PORTB,R16

	LDI R16,0b11111100		; Video 60+CLOCK
	OUT PORTB,R16

	LDI R16,0b11111101		; Video 61+CLOCK
	OUT PORTB,R16

	LDI R16,0b11111110		; Video 62+CLOCK
	OUT PORTB,R16

	LDI R16,0b11111111		; Video 63+CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16

	LDI R16,0b10000000		; CLOCK
	OUT PORTB,R16


	RJMP Loop				; The last LDI/OUT combo is removed to correct the timing
							; error caused by the RJMP. The last and the next-to-last
							; output values are identical so we can just keep the
							; data while the RJMP is executing