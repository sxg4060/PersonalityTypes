 TTL SerialDriver
;****************************************************************
;Description: Serial Driver for UART0 Interrupts 
;Names: Sahil Gogna and Timmy Wang
;Date: 11-11-17
;Class: CMPE-250
;Section: 02,Tuesday, 11:00 AM - 1:00 PM
;---------------------------------------------------------------
;Keil Template for KL46
;R. W. Melton
;September 25, 2017
;****************************************************************
;Assembler directives
            THUMB
            OPT    64  ;Turn on listing macro expansions
;****************************************************************
;Include files
            GET MKL46Z4.s
            OPT  1   ;Turn on listing
;***************************************************************
;Queue Structure Sizes
Q_BUF_SZ EQU 4	;Room for 80 characters
Q_REC_SZ EQU 18 ;Management record size
;EQUates for IRQs/ISRs
;---------------------------------------------------------------
;NVIC_ICER
;31-00:CLRENA=masks for HW IRQ sources;
;             read:   0 = unmasked;   1 = masked
;             write:  0 = no effect;  1 = mask
;22:PIT IRQ mask
;12:UART0 IRQ mask
NVIC_ICER_PIT_MASK    EQU  PIT_IRQ_MASK
NVIC_ICER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_ICPR
;31-00:CLRPEND=pending status for HW IRQ sources;
;             read:   0 = not pending;  1 = pending
;             write:  0 = no effect;
;                     1 = change status to not pending
;22:PIT IRQ pending status
;12:UART0 IRQ pending status
NVIC_ICPR_PIT_MASK    EQU  PIT_IRQ_MASK
NVIC_ICPR_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_IPR0-NVIC_IPR7
;2-bit priority:  00 = highest; 11 = lowest
;--PIT
PIT_IRQ_PRIORITY    EQU  0
NVIC_IPR_PIT_MASK   EQU  (3 << PIT_PRI_POS)
NVIC_IPR_PIT_PRI_0  EQU  (PIT_IRQ_PRIORITY << UART0_PRI_POS)
;--UART0
UART0_IRQ_PRIORITY    EQU  3
NVIC_IPR_UART0_MASK   EQU  (3 << UART0_PRI_POS)
NVIC_IPR_UART0_PRI_3  EQU  (UART0_IRQ_PRIORITY << UART0_PRI_POS)
;---------------------------------------------------------------
;NVIC_ISER
;31-00:SETENA=masks for HW IRQ sources;
;             read:   0 = masked;     1 = unmasked
;             write:  0 = no effect;  1 = unmask
;22:PIT IRQ mask
;12:UART0 IRQ mask
NVIC_ISER_PIT_MASK    EQU  PIT_IRQ_MASK
NVIC_ISER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;PIT_LDVALn:  PIT load value register n
;31-00:TSV=timer start value (period in clock cycles - 1)
;Clock ticks for 0.01 s at 24 MHz count rate
;0.01 s * 24,000,000 Hz = 240,000
;TSV = 240,000 - 1
PIT_LDVAL_10ms  EQU  239999
;---------------------------------------------------------------
;PIT_MCR:  PIT module control register
;1-->    0:FRZ=freeze (continue'/stop in debug mode)
;0-->    1:MDIS=module disable (PIT section)
;               RTI timer not affected
;               must be enabled before any other PIT setup
PIT_MCR_EN_FRZ  EQU  PIT_MCR_FRZ_MASK
;---------------------------------------------------------------
;PIT_TCTRLn:  PIT timer control register n
;0-->   2:CHN=chain mode (enable)
;1-->   1:TIE=timer interrupt enable
;1-->   0:TEN=timer enable
PIT_TCTRL_CH_IE  EQU  (PIT_TCTRL_TEN_MASK :OR: PIT_TCTRL_TIE_MASK)
;---------------------------------------------------------------
;Old Interrupt Lab 9 Equates
;---------------------------------------------------------------
;PORTx_PCRn (Port x pin control register n [for pin n])
;___->10-08:Pin mux control (select 0 to 8)
;Use provided PORT_PCR_MUX_SELECT_2_MASK
;---------------------------------------------------------------
;Port A
PORT_PCR_SET_PTA1_UART0_RX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
PORT_PCR_SET_PTA2_UART0_TX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
;---------------------------------------------------------------
;SIM_SCGC4
;1->10:UART0 clock gate control (enabled)
;Use provided SIM_SCGC4_UART0_MASK
;---------------------------------------------------------------
;SIM_SCGC5
;1->09:Port A clock gate control (enabled)
;Use provided SIM_SCGC5_PORTA_MASK
;---------------------------------------------------------------
;SIM_SOPT2
;01=27-26:UART0SRC=UART0 clock source select
;         (PLLFLLSEL determines MCGFLLCLK' or MCGPLLCLK/2)
; 1=   16:PLLFLLSEL=PLL/FLL clock select (MCGPLLCLK/2)
SIM_SOPT2_UART0SRC_MCGPLLCLK  EQU  \
                                 (1 << SIM_SOPT2_UART0SRC_SHIFT)
SIM_SOPT2_UART0_MCGPLLCLK_DIV2 EQU \
    (SIM_SOPT2_UART0SRC_MCGPLLCLK :OR: SIM_SOPT2_PLLFLLSEL_MASK)
;---------------------------------------------------------------
;SIM_SOPT5
; 0->   16:UART0 open drain enable (disabled)
; 0->   02:UART0 receive data select (UART0_RX)
;00->01-00:UART0 transmit data select source (UART0_TX)
SIM_SOPT5_UART0_EXTERN_MASK_CLEAR  EQU  \
                               (SIM_SOPT5_UART0ODE_MASK :OR: \
                                SIM_SOPT5_UART0RXSRC_MASK :OR: \
                                SIM_SOPT5_UART0TXSRC_MASK)
;---------------------------------------------------------------
;UART0_BDH
;    0->  7:LIN break detect IE (disabled)
;    0->  6:RxD input active edge IE (disabled)
;    0->  5:Stop bit number select (1)
;00001->4-0:SBR[12:0] (UART0CLK / [9600 * (OSR + 1)]) 
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDH_9600  EQU  0x01
;---------------------------------------------------------------
;UART0_BDL
;0x38->7-0:SBR[7:0] (UART0CLK / [9600 * (OSR + 1)])
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDL_9600  EQU  0x38
;---------------------------------------------------------------
;UART0_C1
;0-->7:LOOPS=loops select (normal)
;0-->6:DOZEEN=doze enable (disabled)
;0-->5:RSRC=receiver source select (internal--no effect LOOPS=0)
;0-->4:M=9- or 8-bit mode select 
;        (1 start, 8 data [lsb first], 1 stop)
;0-->3:WAKE=receiver wakeup method select (idle)
;0-->2:IDLE=idle line type select (idle begins after start bit)
;0-->1:PE=parity enable (disabled)
;0-->0:PT=parity type (even parity--no effect PE=0)
UART0_C1_8N1  EQU  0x00
;---------------------------------------------------------------
;UART0_C2
;0-->7:TIE=transmit IE for TDRE (disabled)
;0-->6:TCIE=transmission complete IE for TC (disabled)
;0-->5:RIE=receiver IE for RDRF (disabled)
;0-->4:ILIE=idle line IE for IDLE (disabled)
;1-->3:TE=transmitter enable (enabled)
;1-->2:RE=receiver enable (enabled)
;0-->1:RWU=receiver wakeup control (normal)
;0-->0:SBK=send break (disabled, normal)
UART0_C2_T_R  EQU  (UART0_C2_TE_MASK :OR: UART0_C2_RE_MASK)
;---------------------------------------------------------------
;UART0_C3
;0-->7:R8T9=9th data bit for receiver (not used M=0)
;           10th data bit for transmitter (not used M10=0)
;0-->6:R9T8=9th data bit for transmitter (not used M=0)
;           10th data bit for receiver (not used M10=0)
;0-->5:TXDIR=UART_TX pin direction in single-wire mode
;            (no effect LOOPS=0)
;0-->4:TXINV=transmit data inversion (not inverted)
;0-->3:ORIE=overrun IE for OR (disabled)
;0-->2:NEIE=noise error IE for NF (disabled)
;0-->1:FEIE=framing error IE for FE (disabled)
;0-->0:PEIE=parity error IE for PF (disabled)
UART0_C3_NO_TXINV  EQU  0x00
;---------------------------------------------------------------
;UART0_C4
;    0-->  7:MAEN1=match address mode enable 1 (disabled)
;    0-->  6:MAEN2=match address mode enable 2 (disabled)
;    0-->  5:M10=10-bit mode select (not selected)
;01111-->4-0:OSR=over sampling ratio (16)
;               = 1 + OSR for 3 <= OSR <= 31
;               = 16 for 0 <= OSR <= 2 (invalid values)
UART0_C4_OSR_16           EQU  0x0F
UART0_C4_NO_MATCH_OSR_16  EQU  UART0_C4_OSR_16
;---------------------------------------------------------------
;UART0_C5
;  0-->  7:TDMAE=transmitter DMA enable (disabled)
;  0-->  6:Reserved; read-only; always 0
;  0-->  5:RDMAE=receiver full DMA enable (disabled)
;000-->4-2:Reserved; read-only; always 0
;  0-->  1:BOTHEDGE=both edge sampling (rising edge only)
;  0-->  0:RESYNCDIS=resynchronization disable (enabled)
UART0_C5_NO_DMA_SSR_SYNC  EQU  0x00
;---------------------------------------------------------------
;UART0_S1
;0-->7:TDRE=transmit data register empty flag; read-only
;0-->6:TC=transmission complete flag; read-only
;0-->5:RDRF=receive data register full flag; read-only
;1-->4:IDLE=idle line flag; write 1 to clear (clear)
;1-->3:OR=receiver overrun flag; write 1 to clear (clear)
;1-->2:NF=noise flag; write 1 to clear (clear)
;1-->1:FE=framing error flag; write 1 to clear (clear)
;1-->0:PF=parity error flag; write 1 to clear (clear)
UART0_S1_CLEAR_FLAGS  EQU  0x1F
;---------------------------------------------------------------
;UART0_S2
;1-->7:LBKDIF=LIN break detect interrupt flag (clear)
;             write 1 to clear
;1-->6:RXEDGIF=RxD pin active edge interrupt flag (clear)
;              write 1 to clear
;0-->5:(reserved); read-only; always 0
;0-->4:RXINV=receive data inversion (disabled)
;0-->3:RWUID=receive wake-up idle detect
;0-->2:BRK13=break character generation length (10)
;0-->1:LBKDE=LIN break detect enable (disabled)
;0-->0:RAF=receiver active flag; read-only
UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS  EQU  0xC0
;---------------------------------------------------------------
;---------------------------------------------------------------
;NVIC_ICER
;31-00:CLRENA=masks for HW IRQ sources;
;             read:   0 = unmasked;   1 = masked
;             write:  0 = no effect;  1 = mask
;12:UART0 IRQ mask
;NVIC_ICER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_ICPR
;31-00:CLRPEND=pending status for HW IRQ sources;
;             read:   0 = not pending;  1 = pending
;             write:  0 = no effect;
;                     1 = change status to not pending
;12:UART0 IRQ pending status
;NVIC_ICPR_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_IPR0-NVIC_IPR7
;2-bit priority:  00 = highest; 11 = lowest
;UART0_IRQ_PRIORITY    EQU  3
;NVIC_IPR_UART0_MASK   EQU (3 << UART0_PRI_POS)
;NVIC_IPR_UART0_PRI_3  EQU (UART0_IRQ_PRIORITY << UART0_PRI_POS)
;---------------------------------------------------------------
;NVIC_ISER
;31-00:SETENA=masks for HW IRQ sources;
;             read:   0 = masked;     1 = unmasked
;             write:  0 = no effect;  1 = unmask
;12:UART0 IRQ mask
;NVIC_ISER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;PORTx_PCRn (Port x pin control register n [for pin n])
;___->10-08:Pin mux control (select 0 to 8)
;Use provided PORT_PCR_MUX_SELECT_2_MASK
;---------------------------------------------------------------
UART0_C2_T_RI  EQU  (UART0_C2_RIE_MASK :OR: UART0_C2_T_R) 
UART0_C2_TI_RI  EQU  (UART0_C2_TIE_MASK :OR: UART0_C2_T_RI) 
;----------------------------------------------------------------
;GPIO Equates
;Port D
PTD5_MUX_GPIO EQU (1 << PORT_PCR_MUX_SHIFT)
SET_PTD5_GPIO EQU (PORT_PCR_ISF_MASK :OR: \
				   PTD5_MUX_GPIO)
;Port E
PTE29_MUX_GPIO EQU (1 << PORT_PCR_MUX_SHIFT)
SET_PTE29_GPIO EQU (PORT_PCR_ISF_MASK :OR: \
				    PTE29_MUX_GPIO)
;LED Equates
POS_RED EQU 29
POS_GREEN EQU 5

LED_RED_MASK EQU (1 << POS_RED)
LED_GREEN_MASK EQU (1 << POS_GREEN)
	
LED_PORTD_MASK	EQU LED_GREEN_MASK
LED_PORTE_MASK  EQU LED_RED_MASK
		
;****************************************************************
        EXPORT UART0_IRQHandler
        EXPORT Init_UART0_IRQ
        IMPORT InitQueue
        IMPORT Dequeue
        IMPORT Enqueue
        EXPORT PutChar
        EXPORT GetChar
		EXPORT PIT_ISR
		EXPORT Init_PIT_IRQ
		EXPORT Init_GPIO
        AREA SerialDriver,CODE,READONLY
;*****************************************************************
PIT_ISR				PROC {R0-R13},{}
;Interrupt Service Routine for the PIT module. On a PIT interrupt, if the byte variable
;RunStopWtach is not zero, PIT_ISR increments the word variable Count; otherwise it leaves
;Count unchanged. In either case, make sure the ISR clears the interrupt condition before
;exiting.
;					CPSID I							;Mask all interrupts
					PUSH {LR}						;Push registers to save onto stack
					LDR R0,=RunStopWatch			;Load &RunStopWatch into R0
					LDR R0,[R0,#0]					;Load the value of the watch into R0
					LDR R1,=Count					;Load &Count into R0
					LDR R2,[R1,#0]					;Load the value of the Count into R2
					CMP R0,#0						;Compare watch and 0
					BEQ ExitStartCount				;If watch stops, stop counting time
					ADDS R2,R2,#1					;Increment count
					STR R2,[R1,#0]					;Store the count into R1
ExitStartCount		LDR R0,=PIT_CH0_BASE			;Load Channel 0 into R0
					LDR R1,=PIT_TFLG_TIF_MASK		;Load the mask
					STR R1,[R0,#PIT_TFLG_OFFSET]	;Clear the channel 0 interrupts
					CPSIE I							;Unmask all interrupts
					POP {PC}						;Pop PC	
					ENDP							;End the process
;----------------------------------------------------------------------------------
Init_PIT_IRQ		PROC {R0-R13},{}
;Initialize the PIT to generate an interrupt every 0.01s from PIT channel 0.

;Set SIM_CGC6 for PIT Clock Enabled
					PUSH {R0-R3}					;Push register to save onto stack
					LDR R0,=Count					;Load &count into R0
					LDR R1,=RunStopWatch			;Load &RunStopWatch into R0
					LDR R2,[R0,#0]					;R2 <- *Count
					LDRB R3,[R1,#0]					;R3 <- *RunStopWatch
					MOVS R2,#0						;Set count to 0
					MOVS R3,#0						;Set RunStopWatch to 0
					STR R2,[R0,#0]					;Store new value into &Count
					STRB R3,[R0,#0]					;Store new value into &RunStopWatch
;Start PIT IRq					
					LDR R0,=SIM_SCGC6				;Load SIM_SCGC6 address into R0
					LDR R1,=SIM_SCGC6_PIT_MASK		;Load SCGC6_MASK into R1
					LDR R2,[R0,#0]					;Load the value of the SIM_SCGC6 address into R2
					ORRS R2,R2,R1					;Set the SIM_SCGC6 with the mask
					STR R2,[R0,#0]					;Store set SIM_SCGC6 into R2
;PIT Modyle Control Register (32 bits)
					LDR R0,=PIT_BASE				;Load PIT_BASE into R0
					LDR R1,=PIT_MCR_EN_FRZ			;Load PIT_MCR_EN_FRZ
					STR R1,[R0,#PIT_MCR_OFFSET]		;Store FRZ into BASE with MCR_OFFSET
;PIT Timer Load Value Register (32 bits)
					LDR R0,=PIT_CH0_BASE			;Load channel 0 into R0 
					LDR R1,=PIT_LDVAL_10ms			;Load TSV into R1
					STR R1,[R0,#PIT_LDVAL_OFFSET]	;Store TSV in Channel 0 for timer start value of 239,999
;Enable PIT timer channel 0 for interrupts
					LDR R0,=PIT_CH0_BASE			;Load channel 0 into R0
					MOVS R1,#PIT_TCTRL_CH_IE		;Move PIT_TCTRL into R1
					STR R1,[R0,#PIT_TCTRL_OFFSET]	;Store PIT_TCTRL into CH0
;Initialize PIT Interrupts in NVIC

;Unmask PIT interrupts
					LDR R0,=NVIC_ISER				;R0 = &NVIC_ISER 
					LDR R1,=PIT_IRQ_MASK			;R1 = &PIT_IRQ_MASK
					STR R1,[R0,#0]					;R0 = PIT_IRQ MASK
;Set PIT interrupt priority	
					LDR R0,=PIT_IPR					;R0 = &PIT_IPR
					LDR R1,=(NVIC_IPR_PIT_MASK)		;R1 = &NVIC_IPR_PIT_MASK
					;LDR  R2,=(PIT_IRQ_PRI << PIT_PRI_POS)	
					LDR R3,[R0,#0]					;R3 = *PIT_IPR
					BICS R3,R3,R1					;R3 = R3 & ~R1
					;ORRS R3,R3,R2
					;ASK DR. MELTON ABOUT PRIORITY R3 or R1 to be stored into R0 (LOOK AT SLIDES)
					STR R3,[R0,#0]					;Set PIT interrupt priority
					
;Channel 0 Interrupt Condition

;Clear PIT Channel 0 interrupt
					LDR R0,=PIT_CH0_BASE			;Load channel 0 into R0
					LDR R1,=PIT_TFLG_TIF_MASK		;Load the TFLG into R1
					STR R1,[R0,#PIT_TFLG_OFFSET]	;Clear the PIT Channel 0 interrupt
;End the Init_PIT_IRQ
					POP {R0-R3}						;Pop saved registers
					BX LR							;Branch and exhange link register	
					ENDP							;End the subroutine
;-----------------------------------------------------------------
UART0_IRQHandler			PROC {R0-R13},{}
;Interrupt Service Routine
			CPSID I									;Mask all interrupts
			PUSH {LR}								;Push registers to stack
;Interrupt source can be found in the UART0_S1
			LDR R2,=UART0_BASE						;Load UART0_BASE into R2
			LDRB R0,[R2,#UART0_C2_OFFSET]			;Load UART0_C2 into R0
			MOVS R1,#UART0_C2_TIE_MASK				;Move C2_TIE_MASK into R1
			ANDS R0,R0,R1							;AND R0 and R1 into C2
			BEQ RxEnqueue							;If ANDS returns a 1, then branch to RxEnqueue
TxInterrupt LDRB R0,[R2,#UART0_S1_OFFSET]			;Load UART0_S1 into R0
			MOVS R1,#UART0_S1_TDRE_MASK				;Move TDRE_MASK into R1
			ANDS R0,R0,R1							;AND R0 and R1 into S1
			BEQ RxEnqueue							;If ANDS returns a 1, then branch to RxEnqueue
			LDR R1,=TxQRecord						;Load the Transmit Queue into R1
			BL Dequeue								;Dequeue a character
			BCS DisableTxI							;Branch if dequeue was unsuccessful 
			STRB R0,[R2,#UART0_D_OFFSET]			;Store the character dequeued into UART0_D
			B RxEnqueue								;Branch to RxEnqueue 
DisableTxI	MOVS R1,#UART0_C2_T_RI					;Move the transmitter/reciever register into R1
			STRB R1,[R2,#UART0_C2_OFFSET]			;Store UART0_C2 into R1
RxEnqueue	LDRB R0,[R2,#UART0_S1_OFFSET]			;Load UART0_S1 into R0
			MOVS R1,#UART0_S1_RDRF_MASK				;Load RDRF Mask into R1
			ANDS R0,R0,R1							;AND R0 and R1 into the S1
			BEQ EndUART0ISR							;Branch if equal to EndUART0ISR
			LDRB R0,[R2,#UART0_D_OFFSET]
			LDR R1,=RxQRecord						;Load Receive Queue Record into R1
			BL Enqueue								;Enqueue a character		
EndUART0ISR	CPSIE I									;Unmask all interrupts	
			POP {PC}								;Pop the saved registers
			ENDP									;End the process
												
;-------------------------------------------------------------
Init_UART0_IRQ		PROC {R0-R13},{}
;Interrupt Service Routine for Interrupt Request
			CPSID I														;Mask all interrupts
			PUSH {R0-R2,LR}												;Push registers into stack
			LDR R0,=RxQBuffer											;Load into R0 the Receive Queue Buffer
			LDR R1,=RxQRecord											;Load into R1 the Recieve Queue Record
			MOVS R2,#Q_BUF_SZ											;Load Q_BUF_SZ into R2
			BL InitQueue		  										;Initialize RxQueue			
			LDR R0,=TxQBuffer											;Load into R0 the Transmit Queue Buffer
			LDR R1,=TxQRecord											;Load into R1 the Transmit Queue Buffer
			BL InitQueue		  										;Initialize TxQueue
;Select MCGPLLCLK / 2 UART0 clock source
			LDR	R0,=SIM_SOPT2											;Load SIM_SOPT2's memory address into R0
			LDR R1,=SIM_SOPT2_UART0SRC_MASK								;Load SIM_SOPT2_UART0SRC_MASK into R1
			LDR R2,[R0,#0]												;Load SIM_SOPT2's value into R2
			BICS R2,R2,R1												;Bit Clear (R2 = R2 & ~R1)
			LDR R1,=SIM_SOPT2_UART0_MCGPLLCLK_DIV2						;Load R2 with SIM_SOPT2_UART0_MCGPLLK_DIV2's memory address
			ORRS R2,R2,R1												;Or R2 and R1 together to make R2
			STR R2,[R0,#0]												;Store R2 in R0's effective memory address
;Enable external connection for UART0
			LDR R0,=SIM_SOPT5											;Store SIM_SOPT5's memory address into R0
			LDR R1,=SIM_SOPT5_UART0_EXTERN_MASK_CLEAR					;Store SIM_SOPT5_UART0_EXTERN_MASK's memory address into R1
			LDR R2,[R0,#0]												;Load R0's value into R2
			BICS R2,R2,R1												;Bit Clear (R2 = R2 & ~R1)
			STR R2,[R0,#0]												;Store R2 in R0's effective memory address
;Enable clock for UART0 module 
			LDR R0,=SIM_SCGC4											;Load SIM_SCGC4's memory address in R0
			LDR R1,=SIM_SCGC4_UART0_MASK								;Store SIM_SCGC4's_UART0_MASK's memory address into R1
			LDR R2,[R0,#0]												;Load R0's value into R2
			ORRS R2,R2,R1												;Or (R2 = R2 | R1)
			STR R2,[R0,#0]												;Store R2 in R0's effective memory address
;Enable clock for Port A module 
			LDR R0,=SIM_SCGC5											;Load SIM_SCGC5's memory address in R0
			LDR R1,=SIM_SCGC5_PORTA_MASK								;Load SIM_SCGCS5_PORTA_MASK's address in R1
			LDR R2,[R0,#0]												;Load R0's value in R2
			ORRS R2,R2,R1												;Or (R2 = R2 | R1)
			STR R2,[R0,#0]												;Store R2 in R0's memory address
;Connect PORT A Pin 1 (PTA1) to UART0 Rx (J1 Pin 02)
			LDR R0,=PORTA_PCR1											;Load PORTA_PCR1's memory address in R0
			LDR R1,=PORT_PCR_SET_PTA1_UART0_RX							;Load PORT_PCR_SET_PTA1_UART0_RX's memory address in R1
			STR R1,[R0,#0]												;Store R1 in R0's effective memory address
;Connect PORT A Pin 2 (PTA2) to UART0 Tx (J1 Pin 04)
			LDR R0,=PORTA_PCR2											;Load PORTA_PCR2's memory address in R0
			LDR R1,=PORT_PCR_SET_PTA2_UART0_TX							;Load PORT_PCR_SET_PTA1_UART0_RX's memory address in R1
			STR R1,[R0,#0]												;Load R1 in R0's effective memory address
;Load base address for UART0
			LDR R0,=UART0_BASE											;Load UART0_BASE address in R0
;Disable UART0
			MOVS R1,#UART0_C2_T_R										;Move UART0_C2_T_R address into R1
			LDRB R2,[R0,#UART0_C2_OFFSET]								;Load R0's Byte value into R2
			BICS R2,R2,R1												;Bit Clear (R2 = R2 & R1)
			STRB R2,[R0,#UART0_C2_OFFSET]
;Initialize NVIC for UART0 interrupts
;Set UART0 IRQ priority 
			LDR R0,=UART0_IPR											;Load UART0_IPR into R0
			;LDR R1,=NVIC_IPR_UART0_MASK
			LDR R2,=NVIC_IPR_UART0_PRI_3								;Set a low priority into R2
			LDR R3,[R0,#0]												;Load IPR into R3
			;BICS R3,R3,R1
			ORRS R3,R3,R2												;Set the PRIORITY to 3
			STR R3,[R0,#0]												;Store priority into IPR
;Clear any pending UART0 interrupts
			LDR R0,=NVIC_ICPR											;Load ICPR into R0
			LDR R1,=NVIC_ICPR_UART0_MASK								;Load MASK into R1
			STR R1,[R0,#0]												;Store the UART0 into ICPR
;Unmask UART0 interrupts
			LDR R0,=NVIC_ISER											;Load ISER into R0
			LDR R1,=NVIC_ISER_UART0_MASK								;Load MASK into R1
			STR R1,[R0,#0]												;Store the UART0 into ISEr
;Initialize UART0 for 8N1 format at 9600 baud, and enable recieve interrupt
;Set UART baud rate-BDH before BDL
			LDR R0,=UART0_BASE
			MOVS R1,#UART0_BDH_9600										;Move UART0_BDH_9600 into R1
			STRB R1,[R0,#UART0_BDH_OFFSET]								;Store R1's address in R0's effective memory address based on offset
			MOVS R1,#UART0_BDL_9600										;Move UART_BDL_9600 into R1
			STRB R1,[R0,#UART0_BDL_OFFSET]								;Store R1's address in R0's effective memory address based on offset
;Set UART0 character format for serial bit stream and clear flag
			MOVS R1,#UART0_C1_8N1										;Move UART0_C1_8N1 into R1
			STRB R1,[R0,#UART0_C1_OFFSET]								;Store R1's address in R0's effective memory address based on offset
			MOVS R1,#UART0_C3_NO_TXINV									;Move UART0_C3_NO_TXNIV into R1
			STRB R1,[R0,#UART_C3_OFFSET]                                ;Store R1 in effective memory address of R0
			MOVS R1,#UART0_C4_NO_MATCH_OSR_16                           ;Move UART0_C4_NO_MATCH_OSR_16 into R1
			STRB R1,[R0,#UART0_C4_OFFSET]                               ;Store R1 in effective memory address of R0
			MOVS R1,#UART0_C5_NO_DMA_SSR_SYNC							;Move UART0_C5 into R1
			STRB R1,[R0,#UART0_C5_OFFSET]								;Store R1 in effective memory address of R0
			MOVS R1,#UART0_S1_CLEAR_FLAGS								;Move UART0_S1 in R1
			STRB R1,[R0,#UART0_S1_OFFSET]								;Store R1 in effective memory address of R0
			MOVS R1,#UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS	;Move UART0_S2 in R1	
			STRB R1,[R0,#UART0_S2_OFFSET]								;Store R1 in effective memory address of R0
;Enable UART0
			LDR R0,=UART0_BASE
			MOVS R1,#UART0_C2_T_RI										;Move UART0_C2 in R1
			STRB R1,[R0,#UART0_C2_OFFSET]								;Store R1 into UART0_C2
			POP {R0-R2,PC}												;Pop saved registers
			CPSIE I														;Unmask all interrupts
			ENDP														;End the process
;------------------------------------------------------------------------
;------------------------------------------------
GetChar		PROC {R0-R13},{}
;GetChar is a subroutine that send characters 
;to the RXQueue.
;This subroutine will continously loop until
;the carry flag is not set
			PUSH {R1,LR}				;Push registers that I want to save		
			LDR R1,=RxQRecord			;Load Recieve Queue Record into R1
RepeatRx	CPSID I						;Mask all interrupts
			BL Dequeue					;Dequeue a character from the recieving end
			CPSIE I						;Unmask all interrupts
			BCS RepeatRx				;Loop again if dequeue fails
			POP {R1,PC}					;Pop saved registers
			ENDP						;End process
;--------------------------------------------------				
PutChar		PROC {R0-R13},{}				
;PutChar is a subroutine that transmits characters 
;to the TxQueue.
;This subroutine will continously loop until
;the carry flag is not set
			PUSH {R0-R1,LR}				;Push registers that I want to save
			LDR R1,=TxQRecord			;Load Transmit Queue Record into R1
RepeatTx	CPSID I						;Mask all interrupts
			BL Enqueue					;Enqueue a character from the transmitting end
			CPSIE I						;Unmask all interrupts
			BCS RepeatTx				;Loop again if enqueue fails
			LDR R0,=UART0_BASE			;Load the UART0_BASE into R0
			MOVS R1,#UART0_C2_TI_RI		;Move UART0_C2 in R1
			STRB R1,[R0,#UART0_C2_OFFSET] ;Store R1 into C2
			POP {R0-R1,PC}				;Pop saved registers
			ENDP						;End process
;----------------------------------------------------    
Init_GPIO	PROC {R0-R13},{}
;Enables port/modules to activate lights on KL46 FDRM Board
			PUSH {R0-R3}
;Enabling clock for PORT D and E modules
			LDR R0,=SIM_SCGC5					;Load into R0 &SIM_SCGC5
			LDR R1,=(SIM_SCGC5_PORTD_MASK :O: \	;Load into R1 the orring 
					 SIM_SCGC5_PORTE_MASK)		;of Port D and Port E mem. addresses
			LDR R2,[R0,#0]						;Load SCGC5 value
			ORRS R2,R2,R1						;Set the clock for Port D and E
			STR R2,[R0,#0]						;Store the set values into memory address of SIM_SCGC5
;Select PORT E Pin 29 for GPIO to red LED
			LDR R0,=PORTE_BASE
			LDR R1,=SET_PTE29_GPIO
			STR R1,[R0,#PORTE_PCR29_OFFSET]
;Sekect PORT D Pin 5 for GPIO to green LED
			LDR R0,=PORTD_BASE
			LDR R1,=SET_PTD5_GPIO
			STR R1,[R0,#PORTD_PCR5_OFFSET]
;Select data direction (input or output)
			;RED LED 
			LDR R0,=FGPIOD_BASE
			LDR R1,=LED_PORTD_MASK
			STR R1,[R0,#GPIO_PDDR_OFFSET]
			;GREEN LED 
			LDR R0,=FGPIOE_BASE
			LDR R1,=LED_PORTE_MASK
			STR R1,[R0,#GPIO_PDDR_OFFSET]
			
			;RED LED OFF
			LDR R0,=FGPIOE_BASE
			LDR R1,=LED_RED_MASK
			STR R1,[R0,#GPIO_PSOR_OFFSET]
			
			;GREEN LED OFF
			LDR R0,=FGPIOD_BASE
			LDR R1,=LED_GREEN_MASK
			STR R1,[R0,#GPIO_PSOR_OFFSET]
			
			;RED LED ON
			LDR R0,=FGPIOE_BASE
			LDR R1,=LED_RED_MASK
			STR R1,[R0,#GPIO_PCOR_OFFSET]
			
			;GREEN LED ON
			LDR R0,=FGPIOD_BASE
			LDR R1,=LED_GREEN_MASK
			STR R1,[R0,#GPIO_PCOR_OFFSET]
			
			POP {R0-R3}
			ENDP
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
;Queue structures
RxQBuffer 	SPACE	Q_BUF_SZ	;Recieve Queue Buffer
	ALIGN
RxQRecord	SPACE 	Q_REC_SZ	;Recieve Queue Record
	ALIGN
TxQBuffer   SPACE   Q_BUF_SZ	;Transmit Queue Buffer
	ALIGN
TxQRecord	SPACE	Q_REC_SZ	;Transmit Queue Record
	ALIGN
QBuffer		SPACE   Q_BUF_SZ	;Program Queue Buffer
	ALIGN
QRecord		SPACE 	Q_REC_SZ	;Program Queue Record
	ALIGN
RunStopWatch SPACE 1			;1 = on/0 = off for StopWatch
	ALIGN
Count		SPACE 4 			;Count for PIT Timer
;>>>>>   end variables here <<<<<
            ALIGN
            END