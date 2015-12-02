; ***************************************************************************
; VGA_VSYNC.asm - Part of 2MCUVGA 
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
; ** VERTICAL TIMING **
;		
;		Horizonal Dots         640     640     640
;		Vertical Scan Lines    350     400     480
;		Vert. Sync Polarity    NEG     POS     NEG      
;		Vertical Frequency     70Hz    70Hz    60Hz
;		O (ms)                 14.27   14.27   16.68     Total frame time
;		P (ms)                 0.06    0.06    0.06      Sync length
;		Q (ms)                 1.88    1.08    1.02      Back porch
;		R (ms)                 11.13   12.72   15.25     Active video time
;		S (ms)                 1.2     0.41    0.35      Front porch
;		         ______________________          ________
;		________|        VIDEO         |________|  VIDEO (next frame)
;		    |-Q-|----------R-----------|-S-|
;		__   ______________________________   ___________
;		  |_|                              |_|
;		  |P|
;		  |---------------O----------------|
;		
;		One Frame - 525 lines total per frame 
;		-------------------------------------
;		2 lines front porch 
;		2 lines vertical sync 
;		25 lines back porch 
;		8 lines top border 
;		480 lines video 
;		8 lines bottom border
;		 
;
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
;   Bit 0: Output RAM Address bit 6
;       1: Output RAM Address bit 7 
;       2: Output RAM Address bit 8
;       3: Output RAM Address bit 9
;       4: Output RAM Address bit 10
;       5: 
;       6: Output VSYNC
;       7: 

	
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

	LDI		R17,0x00		; Preloaded value (on) for VSYNC bit on Port A
	LDI		R18,0x00		; Preloaded value (off) for VSYNC bit on Port A

Loop:
	

	RJMP Loop				; The last LDI/OUT combo is removed to correct the timing
							; error caused by the RJMP. The last and the next-to-last
							; output values are identical so we can just keep the
							; data while the RJMP is executing