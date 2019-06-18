#include "macro_register.inc"

; Config ============================================================================
	;External crystal osc frequency
	.EQU	FOSC			=	16000000		;Fuse bit set = using internal 8MHz RC osc

	;Communication BAUD rate
	.EQU	USART_BAUD		=	4800
	.EQU	USART_SCALE		=	FOSC/16/USART_BAUD-1




; Data segment ======================================================================
.DSEG
.ORG	0x0200
	INSTRUCTION:	.BYTE		1024*4

	BEGIN_OF_APP_RAM:

	W_PHASOR:	.BYTE		2
	W_NESTLEVEL:	.BYTE		1
	W_CURRENTCTR:	.BYTE		2
	W_NESTCTR:	.BYTE		14*2
	W_NESTLOCATION:	.BYTE		14*2

	END_OF_APP_RAM:	.BYTE		0






; Code segment ======================================================================
.CSEG

; Interrupt vector map =========================
.ORG	0x0000
	;Power on
	.ORG	0x0000	JMP	INI		;RESET
	;External interrupt
	.ORG	0x0002	JMP	INI		;EXI0
	.ORG	0x0004	JMP	INI		;EXI1
	.ORG	0x0006	JMP	INI		;EXI2
	.ORG	0x0008	JMP	INI		;EXI3
	.ORG	0x000A	JMP	INI		;EXI4
	.ORG	0x000C	JMP	INI		;EXI5
	.ORG	0x000E	JMP	INI		;EXI6
	.ORG	0x0010	JMP	INI		;EXI7
	;Pin change interrupt
	.ORG	0x0012	JMP	INI		;PCI0
	.ORG	0x0014	JMP	INI		;PCI1
	.ORG	0x0016	JMP	INI		;PCI2
	;Watchdog timer
	.ORG	0x0018	JMP	INI		;WDT
	;Timer 2
	.ORG	0x001A	JMP	INI		;T2CA - Compare A
	.ORG	0x001C	JMP	INI		;T2CB
	.ORG	0x001E	JMP	INI		;T2OF - Overflow
	.ORG	0x0020	JMP	INI		;T1CAP - Capture
	;Timer 1
	.ORG	0x0022	JMP	ISR_W_EVENT	;T1CA
	.ORG	0x0024	JMP	INI		;T1CB
	.ORG	0x0026	JMP	INI		;T1CC
	.ORG	0x0028	JMP	INI		;T1OF
	;Timer 0
	.ORG	0x002A	JMP	INI		;T0CA
	.ORG	0x002C	JMP	INI		;T0CB
	.ORG	0x002E	JMP	INI		;T0OF
	;SPI
	.ORG	0x0030	JMP	INI		;SPI
	;USART 0
	.ORG	0x0032	JMP	INI		;U0Rx
	.ORG	0x0034	JMP	INI		;U0E - Data register empty
	.ORG	0x0036	JMP	INI		;U0Tx
	;ADnalog
	.ORG	0x0038	JMP	INI		;AC - Analog compare
	.ORG	0x003A	JMP	INI		;ADC
	;EEPROM
	.ORG	0x003C	JMP	INI		;EEPROM
	;Timer 3
	.ORG	0x003E	JMP	INI		;T3CAP
	.ORG	0x0040	JMP	ISR_X_EVENT	;T3CA
	.ORG	0x0042	JMP	INI		;T3CB
	.ORG	0x0044	JMP	INI		;T3CC
	.ORG	0x0046	JMP	INI		;T3OF
	;USART 1
	.ORG	0x0048	JMP	INI		;U1Rx
	.ORG	0x004A	JMP	INI		;U1E
	.ORG	0x004C	JMP	INI		;U1Tx
	;I2C
	.ORG	0x004E	JMP	INI		;TWI
	;Store program memory
	.ORG	0x0050	JMP	INI		;SPM
	;Timer 4
	.ORG	0x0052	JMP	INI		;T4CAP
	.ORG	0x0054	JMP	ISR_Y_EVENT	;T4CA
	.ORG	0x0056	JMP	INI		;T4CB
	.ORG	0x0058	JMP	INI		;T4CC
	.ORG	0x005A	JMP	INI		;T4OF
	;Timer 5
	.ORG	0x005C	JMP	INI		;T5CAP
	.ORG	0x005E	JMP	ISR_Z_EVENT	;T5CA
	.ORG	0x0060	JMP	INI		;T5CB
	.ORG	0x0062	JMP	INI		;T5CC
	.ORG	0x0064	JMP	INI		;T5OF
	;USART 2
	.ORG	0x0066	JMP	INI		;U2Rx
	.ORG	0x0068	JMP	INI		;U2E
	.ORG	0x006A	JMP	INI		;U2Tx
	;USART 3
	.ORG	0x006C	JMP	INI		;U3Rx
	.ORG	0x006E	JMP	INI		;U3E
	.ORG	0x0070	JMP	INI		;U3Tx

; Const data table =============================


; Subroutin ====================================

#include "func_phasor.inc"

;Send a byte, checking buffer before. Wait if buffer busy.
USART_SEND_BYTE:
	LDS	_RA, UCSR0A
	SBRS	_RA, UDRE0
	JMP	USART_SEND_BYTE
	STS	UDR0, _RT6
	RET

USART_POLL_BYTE:
	LDS	_RA, UCSR0A
	SBRS	_RA, RXC0
	JMP	USART_POLL_BYTE
	LDS	_RT6, UDR0
	RET

;Load Imm value using RT0 (R16)
.MACRO	M_LDRT0
	LDI	R16, @1
	STS	@0, R16
	.ENDMACRO

;Motor step forward/backward
.MACRO	M_MOTORACTIONDIR1	;0:STEP_PIN, 1:STEP_BIT, 2:DIR_PORT, 3:DIR_BIT
	PUSH	_RT0
	LDS	_RT0, @2				;Write 1 to DIR pin
	ORI	_RT0, (1<<@3)
	STS	@2, _RT0
	LDI	_RT0, (1<<@1)				;Rising-edge on STEP pin, motor steps
	STS	@0, _RT0
	NOP						;Delay
	NOP
	NOP
	NOP
	STS	@0, _RT0				;Falling-edge
	POP	_RT0
	.ENDMACRO

.MACRO	M_MOTORACTIONDIR0	;0:STEP_PIN, 1:STEP_BIT, 2:DIR_PORT, 3:DIR_BIT
	PUSH	_RT0
	LDS	_RT0, @2				;Write 0 to DIR pin
	ANDI	_RT0, (0xFF^(1<<@3))
	STS	@2, _RT0
	LDI	_RT0, (1<<@1)				;Rising-edge on STEP pin, motor steps
	STS	@0, _RT0
	NOP						;Delay
	NOP
	NOP
	NOP
	STS	@0, _RT0				;Falling-edge
	POP	_RT0
	.ENDMACRO


; Main routine =================================

;System init
INI:
	;Setup SP
	M_LDRT0	SPH, HIGH(RAMEND)
	M_LDRT0	SPL, LOW(RAMEND)
	CLR	_RZERO

;	;Clock pre-scaler <-- 8
;	M_LDRT0	CLKPR, 0x80
;	M_LDRT0	CLKPR, 0x03

	;Init app ram (reset to 0)
	LDI	_RTAL, LOW(BEGIN_OF_APP_RAM)
	LDI	_RTAH, HIGH(BEGIN_OF_APP_RAM)
	CLR	_RA
	LDI	_RT0, LOW(END_OF_APP_RAM)
	LDI	_RT1, HIGH(END_OF_APP_RAM) 
	INI_appram_reset_loop:
	ST	_RTA+, _RA
	CPSE	_RTAL, _RT0
	JMP	INI_appram_reset_loop
	CPSE	_RTAH, _RT1
	JMP	INI_appram_reset_loop

	;Setup USART communication with PC
	M_LDRT0	UBRR0H, HIGH(USART_SCALE)
	M_LDRT0	UBRR0L, LOW(USART_SCALE)
	M_LDRT0	UCSR0B, 0b00011000
	M_LDRT0	UCSR0C, 0b00001110			;Async USART (UART), no parity, 2 stop bits, 8 bits data

	;Setup IO
	M_LDRT0	DDRC, 0b10101001			;C	2-STEP		2-DIR		2-EN			1-STEP
	M_LDRT0	DDRD, 0b11111100			;D	0-STEP	0-DIR	0-EN	0/1-M3	0/1-M2	0/1-M1
	M_LDRT0	DDRG, 0b00000011			;G					XSW		1-DIR	1-EN
	M_LDRT0	DDRJ, 0b00111000			;J			2-M3	2-M2	2-M1
	M_LDRT0	DDRL, 0b11111100			;L	3-STEP	3-DIR	3-EN	3-M3	3-M2	3-M1

	;Set step motor mode, all motor enabled in 1/32 step mode (M=011,EN=1)
	M_LDRT0	PORTC, 0b00000000
	M_LDRT0	PORTD, 0b00001100
	M_LDRT0	PORTG, 0b00000000
	M_LDRT0	PORTJ, 0b00011000
	M_LDRT0	PORTL, 0b00001100

	;Setup timer - CTC with OCRA
	M_LDRT0	TCCR1B, 0b00001000
	M_LDRT0	TIMSK1, 0b00000010
	M_LDRT0	TCCR3B, 0b00001000
	M_LDRT0	TIMSK3, 0b00000010
	M_LDRT0	TCCR4B, 0b00001000
	M_LDRT0	TIMSK4, 0b00000010
	M_LDRT0	TCCR5B, 0b00001000
	M_LDRT0	TIMSK5, 0b00000010

;;	;Start timer
;;	M_LDRT0	TCCR1B, 0b00001001			;Compare with A register, Clock source = system, Prescaler = 1
;;	M_LDRT0	TIMSK1, 0b00000010			;Enable interrupt on Timer Compare A
;;	
;;	M_LDRT0	OCR1AH, 0x04
;;	M_LDRT0	OCR1AL, 0x00

	;Send OK
	LDI	_RT6, 0xFF
	CALL	USART_SEND_BYTE

	;Enable global interrupt
	SEI

;Receive data from PC
CMD:
	CALL	USART_POLL_BYTE
	MOV	_RS0, _RT6
	MOV	_RT4, _RS0				;Get instruction mode high
	ANDI	_RT4, 0b11110000

	;	Command in RS0
	;	Command mode in RT4, append with 0

	MOV	_RA, _RS0				;Get 1xxxxxxx: Programming mode
	LSL	_RA
	BRCS	CMD_DISP_PROGRAM

	TST	_RT4					;Get 0000xxxx: Stop motors
	BREQ	CMD_DISP_STOP

	CPI	_RT4, 0b00110000			;Get 0011xxxx: Start motor
	BREQ	CMD_DISP_START

	CPI	_RT4, 0b00010000			;Get 0011xxxx: Start motor
	BREQ	CMD_DISP_FORWARD

	CPI	_RT4, 0b00100000			;Get 0011xxxx: Start motor
	BREQ	CMD_DISP_BACKWARD

	CLR	_RT6
	CALL	USART_SEND_BYTE
	JMP	CMD
	
	CMD_DISP_PROGRAM:	JMP	CMD_PROGRAM
	CMD_DISP_STOP:		JMP	CMD_STOP
	CMD_DISP_START:		JMP	CMD_START
	CMD_DISP_FORWARD:	JMP	CMD_FORWARD
	CMD_DISP_BACKWARD:	JMP	CMD_BACKWARD

CMD_PROGRAM:
	LDI	_RTAL, LOW(INSTRUCTION)			;Pointer to instruction buffer
	LDI	_RTAH, HIGH(INSTRUCTION)

	MOV	_RT1, _RS0				;Ceiling
	ANDI	_RT1, 0b01111111
	CLR	_RT0
	ADD	_RT0, _RTAL
	ADC	_RT1, _RTAH

	CLR	_RT2					;Checksum

	CMD_PROGRAM_read:
	CALL	USART_POLL_BYTE				;Read from UART, save and calculate checksum
	ST	_RTA+, _RT6
	ADD	_RT2, _RT6
	CPSE	_RT0, _RTAL
	JMP	CMD_PROGRAM_read			;Check ceiling
	CPSE	_RT1, _RTAH
	JMP	CMD_PROGRAM_read

	MOV	_RT6, _RT2				;Send back checksum
	CALL	USART_SEND_BYTE
	JMP	CMD
	

CMD_STOP:
	CLI						;Prevent motor event, prevent motors lose synch
	LDI	_RT0, 0b00001000			;Write to TCCRnB to stop timer (set clock source to 0)
	MOV	_RA, _RS0
	
	CMD_STOP_z:
	LSR	_RA
	BRCC	CMD_STOP_y
	STS	TCCR5B, _RT0
	
	CMD_STOP_y:
	LSR	_RA
	BRCC	CMD_STOP_x
	STS	TCCR4B, _RT0
	
	CMD_STOP_x:
	LSR	_RA
	BRCC	CMD_STOP_w
	STS	TCCR3B, _RT0
	
	CMD_STOP_w:
	LSR	_RA
	BRCC	CMD_STOP_e
	STS	TCCR1B, _RT0

	CMD_STOP_e:
	SEI

	MOV	_RT6, _RS0				;Send back the command
	CALL	USART_SEND_BYTE
	JMP	CMD


CMD_START:
	CLI
	LDI	_RT0, 0b00001001			;Write to TCCRnB to start timer (set clock source to system clock)
	MOV	_RA, _RS0
	
	CMD_START_z:
	LSR	_RA
	BRCC	CMD_START_y
	STS	TCCR5B, _RT0
	
	CMD_START_y:
	LSR	_RA
	BRCC	CMD_START_x
	STS	TCCR4B, _RT0
	
	CMD_START_x:
	LSR	_RA
	BRCC	CMD_START_w
	STS	TCCR3B, _RT0
	
	CMD_START_w:
	LSR	_RA
	BRCC	CMD_START_e
	STS	TCCR1B, _RT0

	CMD_START_e:
	SEI

	MOV	_RT6, _RS0
	CALL	USART_SEND_BYTE
	JMP	CMD


CMD_FORWARD:
	MOV	_RA, _RS0

	CMD_FORWARD_z:
	LSR	_RA
	BRCC	CMD_FORWARD_y
	M_MOTORACTIONDIR1	PINL, 7, PORTL, 6
	
	CMD_FORWARD_y:
	LSR	_RA
	BRCC	CMD_FORWARD_x
	M_MOTORACTIONDIR1	PINC, 7, PORTC, 5
	
	CMD_FORWARD_x:
	LSR	_RA
	BRCC	CMD_FORWARD_w
	M_MOTORACTIONDIR1	PINC, 0, PORTG, 2
	
	CMD_FORWARD_w:
	LSR	_RA
	BRCC	CMD_FORWARD_e
	M_MOTORACTIONDIR1	PIND, 7, PORTD, 6

	CMD_FORWARD_e:
	LDI	_RT6, 0x89
	CALL	USART_SEND_BYTE
	JMP	CMD

CMD_BACKWARD:
	MOV	_RA, _RS0

	CMD_BACKWARD_z:
	LSR	_RA
	BRCC	CMD_BACKWARD_y
	M_MOTORACTIONDIR0	PINL, 7, PORTL, 6
	
	CMD_BACKWARD_y:
	LSR	_RA
	BRCC	CMD_BACKWARD_x
	M_MOTORACTIONDIR0	PINC, 7, PORTC, 5
	
	CMD_BACKWARD_x:
	LSR	_RA
	BRCC	CMD_BACKWARD_w
	M_MOTORACTIONDIR0	PINC, 0, PORTG, 2
	
	CMD_BACKWARD_w:
	LSR	_RA
	BRCC	CMD_BACKWARD_e
	M_MOTORACTIONDIR0	PIND, 7, PORTD, 6

	CMD_BACKWARD_e:
	MOV	_RT6, _RS0
	CALL	USART_SEND_BYTE
	JMP	CMD


CMD_RELOAD:
	MOV	_RT6, _RS0
	CALL	USART_SEND_BYTE
	JMP	CMD


CMD_STATUE:
	MOV	_RT6, _RS0
	CALL	USART_SEND_BYTE
	JMP	CMD






; Interrupt service routine ====================


;Axis-W event: One step in motor 0
ISR_W_EVENT:
	M_PUSHALL
	SEI
	
;	LDI	_RT7, HIGH(W_PHASOR)
;	LDI	_RT6, LOW(W_PHASOR)
;	CALL	FUNC_PHASOR

	M_MOTORACTIONDIR1	PIND, 7, PORTD, 6


	M_POPALL
	RETI

;Axis-W event: One step in motor 1
ISR_X_EVENT:
	M_PUSHALL
	SEI

	M_POPALL
	RETI

;Axis-W event: One step in motor 2
ISR_Y_EVENT:
	M_PUSHALL
	SEI

	M_POPALL
	RETI

;Axis-W event: One step in motor 3
ISR_Z_EVENT:
	M_PUSHALL
	SEI

	M_POPALL
	RETI
