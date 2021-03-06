				TTL CMPE 250 Exercise 12
;****************************************************************
;This is my first formal project in assembly language.
;My aim is to create a game to figure out your personality type.
;Names: Sahil Gogna and Timmy Wang
;Date: 11-8-17
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
            GET  MKL46Z4.s     ;Included by start.s
            OPT  1   ;Turn on listing
;****************************************************************
CR EQU 0x0D
LF EQU 0x0A
;Queue Management Record Equates (Must be here for Interrupts)
IN_PTR EQU 0	;Buffer address for next enqueue
OUT_PTR EQU 4	;Buffer address for next dequeue
BUF_STRT EQU 8	;Lowest buffer address
BUF_PAST EQU 12	;First address past end of buffer
BUF_SIZE EQU 16	;Size of buffer
NUM_ENQD EQU 17	;Number that was enqueued.
;Queue Structure Sizes
Q_BUF_SZ EQU 4	;Room for 80 characters
Q_REC_SZ EQU 18 ;Management record size
;Timer Module Equates
OneByte	EQU 4
MAX_STRING EQU 79
;----------------------------------------------------------------
;MACRO
		MACRO
$Label 	CRLF $Ri
		PUSH {$Ri,LR}
		MOVS $Ri,#CR	;Carraige Return
		BL PutChar		;Display carraige return
		MOVS $Ri,#LF	;Line feed
		BL PutChar		;Display line feed
		POP {$Ri,LR}
		MEND
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
;PIT_LDVAL_10ms	EQU 239999
;****************************************************************
;Program
;Linker requires Reset_Handler
            AREA    MyCode,CODE,READONLY
            ENTRY
            EXPORT  Reset_Handler
            IMPORT  Startup
			IMPORT InitQueue
			IMPORT Dequeue
			IMPORT Enqueue
			IMPORT PutStringSB
			IMPORT PutNumHex
			IMPORT UART0_IRQHandler
			IMPORT Init_UART0_IRQ
			IMPORT GetChar
			IMPORT PutChar
			IMPORT BOTH_ON
			IMPORT BOTH_OFF
			IMPORT GREEN_ON
			IMPORT GREEN_OFF
			IMPORT RED_ON
			IMPORT RED_OFF
Reset_Handler  PROC  {},{}
main
;---------------------------------------------------------------
;Mask interrupts
            CPSID   I				;Mask all interrupts
;KL46 system startup with 48-MHz system clock
            BL      Startup			;Set all registers
;---------------------------------------------------------------
;>>>>> begin main program code <<<<<

			BL Init_UART0_IRQ		;Initialize UART0 for serial driver
			BL Init_PIT_IRQ			;Initialize PIT Timer
			CPSIE I					;Unmask interrupts from KL46 devices
;----------------------------------------------------------------
			LDR R0,=Welcome			;Load the welcome message into R0
			MOVS R5,#MAX_STRING		;Load in a buffer capacity for the string
			BL PutStringSB			;Display the welcome message on the terminal			
			BL CRLF 					;Carriage Return and Line Feed (equivalent to hitting the enter key)
			;First Question
rep			LDR R0,=Question1		;Load the first question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user	
			;Initializing Timer here
			LDR R2,=RunStopWatch	;Load in stop watch boolean
			MOVS R3,#1				;Load a 1 into R6 to set stop watch boolean
			STRB R3,[R2,#0]			;Move a one into the stop watch to let the count increment
			BL GetChar				;Get a character from the user
			LDR R4,=Choices			;Load in the memory address of Choice
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed (equivalent to hitting the enter key)
			;Second Question
			LDR R0,=Question2		;Load the first question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			BL GetChar				;Get a character from the user
			BL PutChar
			;LDR R4,=Choices		;Load in the memory address of Choice
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed (equivalent to hitting the enter key)
			;Third Question
			LDR R0,=Question3		;Load the second question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user		
			BL GetChar				;Get a character from the user
			BL PutChar
			;LDR R4,=Choices		;Load in the memory address of Choice
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed (equivalent to hitting the enter key)
			;Fourth Question
			LDR R0,=Question4		;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user			
			BL GetChar				;Get a character from the user
			BL PutChar
			;LDR R4,=Choices		;Load in the memory address of Choice
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Fifth Question
			LDR R0,=Question5		;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user			
			BL GetChar				;Get a character from the user
			BL PutChar
			;LDR R4,=Choices		;Load in the memory address of Choice
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Sixth Question
			LDR R0,=Question6		;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user			
			BL GetChar				;Get a character from the user
			BL PutChar
			;LDR R4,=Choices		;Load in the memory address of Choice
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Seventh Question
			LDR R0,=Question7		;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			BL GetChar				;Get a character from the user
			BL PutChar
			;LDR R4,=Choices		;Load in the memory address of Choice
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Eigth Question
			LDR R0,=Question8		;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user			
			BL GetChar				;Get a character from the user
			BL PutChar
			;LDR R4,=Choices		;Load in the memory address of Choice
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Stop Counter
			LDR R0,=RunStopWatch	;Load in stop watch boolean
			MOVS R6,#0				;Move a 0 into R6
			STRB R6,[R0,#0]			;Turn off PIT Timer
			;Give total time it took to take the test
			BL CRLF					;Carriage Return and Line Feed
			LDR R0,=TimeT			;Load in time display
			MOVS R1,R5				;Move R5,R1
			BL PutStringSB			;Display time message
			LDR R7,=Count			;Load count
			LDR R1,[R7,#0]			;Load value of count into R0
			MOVS R0,R1				;Movs R1 into R0
			BL PutNumU				;Display time it took to finish the test
			LDR R0,=Count			;Load in &Count
			MOVS R1,#0				;Move 0 into R1
			STR R1,[R0,#0]			;Reset counter
			MOVS R0,#0x20			;SPACE
			BL PutChar				;Display SPACE
			MOVS R0,#'x'			;Move a 'x' into R0
			BL PutChar				;Display 'x'
			MOVS R0,#0x20			;SPACE
			BL PutChar				;Display SPACE
			LDR R0,=TimeP			;Load the time prompt
			MOVS R1,#MAX_STRING		;Move a string buffer cap into R1
			BL PutStringSB			;Display "0.01s"
			BL CRLF					;CR and LF
			;Give choice
			LDR R4,=Choices			;Load in all the choices
			LDR R0,=List			;Load in list of choices prompt
			MOVS R1,R5				;Move in MAX_STRING	
			BL PutStringSB			;Display choices prompt
			MOVS R7,#0				;Counter for size of choices array
loopC		CMP R7,#8				;Compare R7 to size
			BEQ decision			;Branch if equal to Decision
			LDRB R0,[R4,R7]			;Load in choice
			ADDS R7,R7,#1			;Increment counter
			BL PutChar				;Display choice
			B loopC					;keep looping
decision	BL CRLF					;New Line
			LDR R0,=Repeat			;Check to see if choices are okay
invalidState BL PutStringSB			;Display prompt
			BL GetChar				;Recieve character
			CMP R0,#'y'				;Check if 'y'
			BEQ yes					;yes
			CMP R0,#'Y'				;Check if 'Y'
			BEQ yes					;yes
			CMP R0,#'n'				;Check if 'n'
			BEQ no					;no
			CMP R0,#'N'				;Check if 'N'
			BEQ no					;no
			B invalidState			;If invalid, then loop again for response
yes			BL CRLF					;New Line
			B rep					;Repeat test
no			BL CRLF					;New Line
			LDR R0,=Decision		;Load in decision prompt
			BL PutStringSB			;Display decision prompt
			BL DecideEI				;Decide upon Extraverted/Intraverted
			BL DecideSN				;Decide upon Sensing/Intuition
			BL DecideTF				;Decide upon thinking/feeling
			BL DecideJP				;Decide upon judging/percieving 
			PUSH {R1}				;Push score
			BL CRLF					;Carriage Return and Line Feed
			LDR R0,=Score			;Score prompt
			MOVS R1,R5				;Move R5 into R1 (MAX_STRING)
			BL PutStringSB			;Display score prompt
			POP {R1}				;Pop R1
			MOVS R0,R1				;Move R1 into R0
            CMP R0,#0
            BLT negative
            B positive
negative    MVNS R5,R0
            MOVS R0,#'-'
            BL PutChar
            ;MOVS R0,R5
            ADDS R0,R5,#1
            B positive
positive             
			BL PutNumU				;Display score
			B .						;End test
;>>>>>   end main program code <<<<<
;Stay here
			ENDP 					;End Main
			LTORG					;LTORG for far branching
;----------------------------------------------------------------------------------
;>>>>> begin subroutine code <<<<<
;*****************************************************************
PIT_ISR				PROC {R0-R13},{}
;Interrupt Service Routine for the PIT module. On a PIT interrupt, if the byte variable
;RunStopWtach is not zero, PIT_ISR increments the word variable Count; otherwise it leaves
;Count unchanged. In either case, make sure the ISR clears the interrupt condition before
;exiting.
					CPSID I							;Mask all interrupts
					PUSH {LR}						;Push registers to save onto stack
					LDR R0,=RunStopWatch			;Load &RunStopWatch into R0
					LDRB R0,[R0,#0]					;Load the value of the watch into R0
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
					STRB R3,[R1,#0]					;Store new value into &RunStopWatch
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
;----------------------------------------------------------------------------------
CRLF				PROC {R0-R13},{}
;Carriage Return and Line Feed subroutine
;Input: R0
;Output: New Line
					PUSH {R0,LR}	;Push saved registers
					MOVS R0,#CR		;Carraige Return
					BL PutChar		;Display carraige return
					MOVS R0,#LF		;Line feed
					BL PutChar		;Display line feed
					POP {R0,PC}		;Pop saved registers
					ENDP			;End subroutine
;-----------------------------------------------------------------------------------
GetStringSB PROC {R0-R13},{}
;GetStringSB is a subroutine that reads a string
;from the terminal keyboard to memory starting at 
;the address in R0 and adds null termination.
;R0 = Initially the memory address of the String put into the terminal
;R1 = Buffer Capacity
;R2 = This Reg. gets R0's contents before calling GetChar, which will overwrite R0
;R3 = Pointer

            PUSH {R0-R3,LR} 	;Push Saved Registers
			
            MOV R2,R0           ;Move R0's contents into R2 before calloing GetChar, which will overwrite R0's contents
            MOVS R3,#0          ;Initialize counter R3 with 0
			SUBS R1,R1,#1		;Decrement the MAX_STRING value by one to account for the null character
While   	BL GetChar       ;Call GetChar to get the character from the user input
			CMP R0,#0x0D        ;Compare input to carriage return to see if it has reached character return
            BEQ NullTerminate	;Branch to null terminate if the character recieved was a carriage return
			CMP R0,#0x1F		;Compare input to special keys
			BLO While			;If the input is less than 0x1F, then ignore the character and branch back to while
			CMP R0,#0x7F		;Compare input to delete
			BEQ IgnoreBack		;If the input is 0x07F, then branch to IgnoreBack, which null terminates the character
			BL PutChar			;Display the character on the terminal
			STRB R0,[R2,R3]		;Store the character into the String's memory address in R2, with an offset of R3
			ADDS R3,R3,#1		;Increment counter to go to next index of the string
			CMP R3,R1         	;Compare my counter to the max string size
			BLO While			;If counter < max_string, continue looping and taking in character
While2   	BL GetChar		    ;If counter >= max_string, take in another character
			CMP R0,#0x0D        ;Compare input to carriage return to see if it has reached carriage return
            BEQ NullTerminate	;If input was equal to carriage return, then branch to NullTerminate 
			B While2			;If not equal to carriage return, then branch to While2
			
			
IgnoreBack  BL   PutChar		;If input != Carriage return, branch here and display the next character
    		SUBS R3,R3,#1		;Decrement counter to go back and null a character
			MOVS R0,#0          ;Move NULL(0) into R0
            STRB R0,[R2,R3]     ;Store the null byte, R0, into the memory address of the string with and offset of R3		
			B While				;Branch back to while to input another character
			
						
NullTerminate BL PutChar		;Display the carriage return on the terminal
              MOVS R0,#0	    ;Null terminate the string
              STRB R0,[R2,R3]   ;Store null terminated string in R2 with R3 offset
              MOVS R0,#0x0A     ;Line Feed to upadate line
			  BL PutChar		;Put the LF on the terminal
			  B EndGetStringSB	;End the Loop

EndGetStringSB					;Label denoting end of the subroutine
				POP {R0-R3,PC}  ;Pop saved registers
				ENDP			;End Process
;--------------------------------------------------------------------------------------
DIVU		PROC {R2-R14},{}		; Define Subroutine name 'DIVU' along with Registers that are not affected on return
;*********************************
;DIVU is a subroutine that simulates
;a division operation on two numbers
;Inputs:
;R0: Divisor
;R1: Dividend
;Outputs:
;R1 / R0 = R0 remainder R1
;*******************************
			PUSH {R2-R4}		; Push R2-R4 so that these values do not change during each loop
;*******************************
			MOVS R2,#0			; Move 0 into R2 to act as the quotient
			CMP R0,#0			; Compare R0 and zero to see if they are equal, if so, the carry flag will be set
			BEQ RaiseCarry		; If R0 = 0, then the code will branch off to the 'RaiseCarry' Label
WhileDIVU	CMP R1,R0			; Beginning of while loop, in which the dividend and divisor are compared
			BLT End1While		; If the Dividend (R1) < Divisor (R0), then the code will branch off to the EndWhile Label
			SUBS R1,R1,R0		; Dividend = Dividend - Divisor
			ADDS R2,R2,#1		; R2 is incremented by 1 to show how many times the divisor goes into the dividend
			B 	WhileDIVU		; Branch back to the while loop after each iteration to show how many times the divisor goes into the dividend

RaiseCarry	MRS R3,APSR			; Move to special register from R3
			LDR R4,=0x20000000	; Load R4 with 0x20000000 to set the carry flag without affecting other flags
			ORRS R3,R3,R4		; R3 = R3 | R4, will set off the carry bit (20000000 | 00000000 = 20000000)
			MSR APSR,R3			; Move to R3 from special register
			B EndDIVU			; Branch back to the EndWhile Label to reset the flag and prepare for next inputs
			
End1While	MOVS R0,R2			; Move the quotient (R2) to R0
            MRS R3,APSR			; Move to special register from R3 
			BICS R3,R3,R4		; Bit clear R3 and R4 to reset carry flag without changing the other flags
			MSR APSR,R3			; Move to R3 from special register
			POP{R2-R4}			; Pop R2-R4 to restore those saved values
			BX LR				; Branch Exhange with Link Register	to branch back to the code where BL DIVU was called
			ENDP				; End process
				
EndDIVU		BX LR				; Branch Exchange with Link Regster to branch back to the code to since the result sets the C flag
;---------------------------------------------------------------
PutNumU		PROC {R0-R13},{}
;R0 = Unsigned Word Variable
;Uses DIVU Subroutine to convert from 
;Hexidecimal to Decimal 
;and print it to terminal
			PUSH {R0-R3,LR}			;Push inputs in
			MOVS R1,R0
			MOVS R0,#10				;Move 10 into R0 as divisor
			MOVS R3,#0				;Initialize Counter
Division	BL DIVU					;Call division subroutine
			PUSH {R1}				;Push the remainders into the stack
			ADDS R3,R3,#1			;Move pointer by one 
			CMP R0,#0				;Compare Quotient against zero
			BEQ PopAll				;Pop all if Quotient = 0
			MOVS R1,R0				;Move quotient into R1
			MOVS R0,#10				;Move 10 into R0 to begin the division process again
			B Division				;Branch back to beginning of loop

PopAll		POP {R0}				;Pop remainders into R0	
			SUBS R3,R3,#1			;Decrement counter by 1 
			ADDS R0,R0,#0x30		;Add 30 to R0 to convert to ASCII
			BL PutChar				;Print the value popped
			CMP R3,#0				;Compare counter to 0
			BEQ EndPutNumU			;Pop R1's contents into R0			
			B PopAll				;Continue popping all until R3 = 0
EndPutNumU
			POP {R0-R3,PC}			;Pop them out
			ENDP					;End Process

;----------------------------------------------------------------
PutNumUB	PROC {R0-R13},{}
;This subroutine prints to the terminal screen the text decimal 
;representation of the unsigned byte value in R0.  (For example, 
;if R0 contains 0x003021101, then 1 should print on the terminal.  
;Note:  001 would also be acceptable.)  
;Input: R0: Unsigned Word Variable
			PUSH {R0-R7,LR}				;Push registers to save onto stack, as well as link register
			MOVS R1,#0xFF				;Create a mask to isolate the last byte of address
			ANDS R0,R0,R1				;AND R0 and R1 to isolate the last byte
			BL PutNumU					;Call PutNumU to display the byte
			POP{R0-R7,PC}				;Pop saved register
			ENDP						;End Subroutine
;-----------------------------------------------------------------
DisplayChoices	PROC {R0-R13},{}
;Subroutine that displays all the choices to the user
;Inputs: N/A
;Outputs:
;Displays the choices in R0
			PUSH {R0-R1,LR}		;Push registers to modify into stack
			MOVS R1,#MAX_STRING	;Set a buffer capacity
			BL CRLF				;Enter Key
			LDR R0,=Yes			;Load Strongly Disagree choice
			BL PutStringSB		;Display the choice
			BL CRLF				;Enter Key
			LDR R0,=Unsure			;Load Disagree moderately
			BL PutStringSB		;Display the choice
			BL CRLF				;Enter Key
			LDR R0,=No			;Load Disagree a little
			BL PutStringSB		;Display the choice
			BL CRLF				;Enter Key
			POP {R0-R1,PC}		;Pop registers
			ENDP				;End subroutine
;-------------------------------------------------------------------
CheckChoices	PROC {R0-R13},{}
;Subroutine that checks the users choices
;Inputs: 
;R0 = Holds the answer that the user typed.
;R1 = Memory address of choice
;Outputs: Stores answer choice in memory
				PUSH {R1,LR}		    ;Push registers to modify onto stack.
				CMP R0,#'A'			    ;Check if answer is 'A'
				BEQ green			    ;Light green LED
				CMP R0,#'B'			    ;Check if answer is 'B'
				BEQ both			    ;Light both red and green LEDs
				CMP R0,#'C'			    ;Check if answer is 'C'
				BEQ red				    ;Light red LED
checkA			CMP R0,#'a'			    ;Compare input to 'a'
				BHS checktheZ		    ;Checks if input is less than z
				B tryAgain			    ;If it is not zero, then
checktheZ		CMP R0,#'c'		 		;Compare input to 'f'
				BLS validLetter	 		;It's valid if in the range
				BHS tryAgain			;If input > 'z,' end the checker
tryAgain		BL CRLF					;New Line
				MOVS R1,#MAX_STRING		;Set a size limit for MAX_STRING
				LDR R0,=invalidChoice	;Load in invalid choice prompt
				BL PutStringSB			;Display prompt
				BL CRLF					;New line
				BL GetChar				;Get another character
				BL PutChar				;Display that character
				B checkA				;Check again to see if it is valid
validLetter		
				SUBS R0,R0,#0x20 		;Convert to ASCII
				CMP R0,#'A'				;Check if 'A' is the answer
				BEQ green				;Branch if equal to green
				CMP R0,#'B'				;Check if 'B' is the answer
				BEQ both				;Branch if equal to both 
				CMP R0,#'C'				;Check if 'C' is the answer
				BEQ red					;Branch if equal to red
green			BL BOTH_OFF				;Turn LED's off
				BL GREEN_ON				;Turn green LED on
				B store					;Store choice
red				BL BOTH_OFF				;Turn LED's off
				BL RED_ON				;Turn RED LED on
				B store					;Store choice
both			BL BOTH_OFF				;Turn LED's off
				BL BOTH_ON				;Turn both
				B store					;Store choice
store			STRB R0,[R4,#0]			;Store answer choice into memory
				ADDS R4,R4,#1			;Increment pointer
				POP {R1,PC}				;Pop R1 and PC
				ENDP					;End Process

;---------------------------------------------------------------
DecideEI		PROC {R0-R13},{}
;This subroutine gives the user an extraverted or intraverted response
;Inputs:
;R0 = M[choices]
;R1 = Score
;R2 = Counter for Size of Array
;Outputs:
;R0 = Your personality type
				PUSH {LR}				;Push saved registers
				MOVS R1,#0				;Reset score
				MOVS R2,#0				;Reset counter
EI				CMP R2,#2				;Set loop condition
				BEQ EndDecideEI			;Decide the choice 
				LDRB R3,[R4,#0]			;Load in first value
				ADDS R4,R4,#1			;Increment pointer
				CMP R3,#'A'				;Check if choice was 'A'
				BEQ IncrementEI			;Increment 
				CMP R3,#'B'				;Check if choice was 'B'
				BEQ NoIncrementEI		;Do nothing
				CMP R3,#'C'				;Check if choice was 'C'
				BEQ DecrementEI			;Decrement
NoIncrementEI	
                ADDS R2,R2,#1			;Increment index
				B EI					;Loop again
				
IncrementEI		
                ADDS R1,R1,#1			;Increment score
				ADDS R2,R2,#1			;Increment pointer
				B EI					;Loop
DecrementEI		
                SUBS R1,R1,#1			;Decrement score
				ADDS R2,R2,#1			;Increment pointer
				B EI					;Loop

EndDecideEI		CMP R1,#0				;Compare score against 0
				BGT Extra				;Check if greater than
				BLT Intra				;Check if less than
				BEQ UnknownEI			;Check if equal
Extra			MOVS R0,#'E'			;Give letter result
				BL PutChar				;Display result	
				B EndEI					;End sub
Intra			MOVS R0,#'I'			;Give letter result
				BL PutChar				;Display result
				B EndEI					;End sub
UnknownEI		PUSH {R1}				;Store R1
				MOVS R1,#MAX_STRING		;R1 <- MAX_STRING
				LDR R0,=TooClose		;Load in too close to call prompt
				BL PutStringSB			;Display the string
				POP {R1}				;Pop R1
EndEI			POP {PC}				;Pop PC
				ENDP					;End Subroutine
;----------------------------------------------------------------
DecideSN		PROC {R0-R13},{}
;This subroutine gives the user an extraverted or intraverted response
;Inputs:
;R0 = M[choices]
;R1 = Score
;R2 = Counter for Size of Array
;Outputs:
;R0 = Your personality type
				PUSH {LR}				;Push saved registers
				;MOVS R1,#0              ;Reset score
				MOVS R2,#0              ;Reset counter
SN				CMP R2,#2               ;Set loop condition
				BEQ EndDecideSN         ;Decide the choice 
				LDRB R3,[R4,#0]         ;Load in first value
				ADDS R4,R4,#1           ;Increment pointer
				CMP R3,#'A'             ;Check if choice was 'A'
				BEQ IncrementSN         ;Increment 
				CMP R3,#'B'             ;Check if choice was 'B'
				BEQ NoIncrementSN       ;Do nothing
				CMP R3,#'C'             ;Check if choice was 'C'
				BEQ DecrementSN         ;Decrement
NoIncrementSN	
                ADDS R2,R2,#1           ;Increment index
				B SN                    ;Loop again
				                        
IncrementSN		
                ADDS R1,R1,#1           ;Increment score
				ADDS R2,R2,#1           ;Increment pointer
				B SN                    ;Loop
DecrementSN		
                SUBS R1,R1,#1           ;Decrement score
				ADDS R2,R2,#1           ;Increment pointer
				B SN                    ;Loop
                                        
EndDecideSN		CMP R1,#0               ;Compare score against 0
				BGT Sense               ;Check if greater than
				BLT Intuition           ;Check if less than
				BEQ UnknownSN           ;Check if equal
Sense			MOVS R0,#'S'            ;Give letter result
				BL PutChar              ;Display result	
				B EndSN                 ;End sub
Intuition		MOVS R0,#'N'            ;Give letter result
				BL PutChar              ;Display result
				B EndSN                 ;End sub
UnknownSN		PUSH {R1}               ;Store R1
				MOVS R1,#MAX_STRING     ;R1 <- MAX_STRING
				LDR R0,=TooClose        ;Load in too close to cal
				BL PutStringSB          ;Display the string
				POP {R1}                ;Pop R1
EndSN			POP {PC}                ;Pop PC
				ENDP                    ;End Subroutine
;----------------------------------------------------------------
DecideTF		PROC {R0-R13},{}
;This subroutine gives the user an extraverted or intraverted response
;Inputs:
;R0 = M[choices]
;R1 = Score
;R2 = Counter for Size of Array
;Outputs:
;R0 = Your personality type
				PUSH {LR}				;Push saved registers
				;MOVS R1,#0              ;Reset score
				MOVS R2,#0              ;Reset counter
TF				CMP R2,#2               ;Set loop condition
				BEQ EndDecideTF         ;Decide the choice 
				LDRB R3,[R4,#0]         ;Load in first value
				ADDS R4,R4,#1           ;Increment pointer
				CMP R3,#'A'             ;Check if choice was 'A'
				BEQ IncrementTF         ;Increment 
				CMP R3,#'B'             ;Check if choice was 'B'
				BEQ NoIncrementTF       ;Do nothing
				CMP R3,#'C'             ;Check if choice was 'C'
				BEQ DecrementTF         ;Decrement
NoIncrementTF	
                ADDS R2,R2,#1           ;Increment index
				B TF                    ;Loop again
				                        
IncrementTF		
                ADDS R1,R1,#1           ;Increment score
				ADDS R2,R2,#1           ;Increment pointer
				B TF                    ;Loop
DecrementTF		
                SUBS R1,R1,#1           ;Decrement score
				ADDS R2,R2,#1           ;Increment pointer
				B TF                    ;Loop
                                        
EndDecideTF		CMP R1,#0               ;Compare score against 0
				BGT Think               ;Check if greater than
				BLT Feel                ;Check if less than
				BEQ UnknownTF           ;Check if equal
Think			MOVS R0,#'T'            ;Give letter result
				BL PutChar              ;Display result	
				B EndTF                 ;End sub
Feel			MOVS R0,#'F'            ;Give letter result
				BL PutChar              ;Display result
				B EndTF                 ;End sub
UnknownTF		PUSH {R1}               ;Store R1
				MOVS R1,#MAX_STRING     ;R1 <- MAX_STRING
				LDR R0,=TooClose        ;Load in too close to cal
				BL PutStringSB          ;Display the string
				POP {R1}                ;Pop R1
EndTF			POP {PC}                ;Pop PC
				ENDP                    ;End Subroutine
;----------------------------------------------------------------
DecideJP		PROC {R0-R13},{}
;This subroutine gives the user an extraverted or intraverted response
;Inputs:
;R0 = M[choices]
;R1 = Score
;R2 = Counter for Size of Array
;Outputs:
;R0 = Your personality type
				PUSH {LR}				;Push saved registers
				;MOVS R1,#0              ;Reset score
				MOVS R2,#0              ;Reset counter
JP				CMP R2,#8               ;Set loop condition
				BEQ EndDecideJP         ;Decide the choice 
				LDRB R3,[R4,#0]         ;Load in first value
				ADDS R4,R4,#1           ;Increment pointer
				CMP R3,#'A'             ;Check if choice was 'A'
				BEQ IncrementJP         ;Increment 
				CMP R3,#'B'             ;Check if choice was 'B'
				BEQ NoIncrementJP       ;Do nothing
				CMP R3,#'C'             ;Check if choice was 'C'
				BEQ DecrementJP         ;Decrement
NoIncrementJP	
                ADDS R2,R2,#1           ;Increment index
				B JP                    ;Loop again
				                        
IncrementJP		
                ADDS R1,R1,#1           ;Increment score
				ADDS R2,R2,#1           ;Increment pointer
				B JP                    ;Loop
DecrementJP		
                SUBS R1,R1,#1           ;Decrement score
				ADDS R2,R2,#1           ;Increment pointer
				B JP                    ;Loop
                                        
EndDecideJP		CMP R1,#0               ;Compare score against 0
				BGT Judge               ;Check if greater than
				BLT Percieve            ;Check if less than
				BEQ UnknownJP           ;Check if equal
Judge			MOVS R0,#'J'            ;Give letter result
				BL PutChar              ;Display result	
				B EndJP                 ;End sub
Percieve		MOVS R0,#'P'            ;Give letter result
				BL PutChar              ;Display result
				B EndJP                 ;End sub
UnknownJP		PUSH {R1}               ;Store R1
				MOVS R1,#MAX_STRING     ;R1 <- MAX_STRING
				LDR R0,=TooClose        ;Load in too close to cal
				BL PutStringSB          ;Display the string
				POP {R1}                ;Pop R1
EndJP			POP {PC}                ;Pop PC
				ENDP                    ;End Subroutine
;>>>>>   end subroutine code <<<<<
            ALIGN
;****************************************************************
;Vector Table Mapped to Address 0 at Reset
;Linker requires __Vectors to be exported
            AREA    RESET, DATA, READONLY
            EXPORT  __Vectors
            EXPORT  __Vectors_End
            EXPORT  __Vectors_Size
            IMPORT  __initial_sp
            IMPORT  Dummy_Handler
            IMPORT  HardFault_Handler
__Vectors 
                                      ;ARM core vectors
            DCD    __initial_sp       ;00:end of stack
            DCD    Reset_Handler      ;01:reset vector
            DCD    Dummy_Handler      ;02:NMI
            DCD    HardFault_Handler  ;03:hard fault
            DCD    Dummy_Handler      ;04:(reserved)
            DCD    Dummy_Handler      ;05:(reserved)
            DCD    Dummy_Handler      ;06:(reserved)
            DCD    Dummy_Handler      ;07:(reserved)
            DCD    Dummy_Handler      ;08:(reserved)
            DCD    Dummy_Handler      ;09:(reserved)
            DCD    Dummy_Handler      ;10:(reserved)
            DCD    Dummy_Handler      ;11:SVCall (supervisor call)
            DCD    Dummy_Handler      ;12:(reserved)
            DCD    Dummy_Handler      ;13:(reserved)
            DCD    Dummy_Handler      ;14:PendableSrvReq (pendable request 
                                      ;   for system service)
            DCD    Dummy_Handler      ;15:SysTick (system tick timer)
            DCD    Dummy_Handler      ;16:DMA channel 0 xfer complete/error
            DCD    Dummy_Handler      ;17:DMA channel 1 xfer complete/error
            DCD    Dummy_Handler      ;18:DMA channel 2 xfer complete/error
            DCD    Dummy_Handler      ;19:DMA channel 3 xfer complete/error
            DCD    Dummy_Handler      ;20:(reserved)
            DCD    Dummy_Handler      ;21:command complete; read collision
            DCD    Dummy_Handler      ;22:low-voltage detect;
                                      ;   low-voltage warning
            DCD    Dummy_Handler      ;23:low leakage wakeup
            DCD    Dummy_Handler      ;24:I2C0
            DCD    Dummy_Handler      ;25:I2C1
            DCD    Dummy_Handler      ;26:SPI0 (all IRQ sources)
            DCD    Dummy_Handler      ;27:SPI1 (all IRQ sources)
            DCD    UART0_IRQHandler	  ;28:UART0 (status; error)
            DCD    Dummy_Handler      ;29:UART1 (status; error)
            DCD    Dummy_Handler      ;30:UART2 (status; error)
            DCD    Dummy_Handler      ;31:ADC0
            DCD    Dummy_Handler      ;32:CMP0
            DCD    Dummy_Handler      ;33:TPM0
            DCD    Dummy_Handler      ;34:TPM1
            DCD    Dummy_Handler      ;35:TPM2
            DCD    Dummy_Handler      ;36:RTC (alarm)
            DCD    Dummy_Handler      ;37:RTC (seconds)
            DCD    PIT_ISR		      ;38:PIT (all IRQ sources)
            DCD    Dummy_Handler      ;39:I2S0
            DCD    Dummy_Handler      ;40:USB0
            DCD    Dummy_Handler      ;41:DAC0
            DCD    Dummy_Handler      ;42:TSI0
            DCD    Dummy_Handler      ;43:MCG
            DCD    Dummy_Handler      ;44:LPTMR0
            DCD    Dummy_Handler      ;45:Segment LCD
            DCD    Dummy_Handler      ;46:PORTA pin detect
            DCD    Dummy_Handler      ;47:PORTC and PORTD pin detect
__Vectors_End
__Vectors_Size  EQU     __Vectors_End - __Vectors
            ALIGN
;****************************************************************
;Constants
            AREA    MyConst,DATA,READONLY
;>>>>> begin constants here <<<<<
;Welcome Message
Welcome DCB "Welcome to the personality test! Let's begin!",0
;Questions

Question1	DCB		"1. I see myself as enthusiastic.",0
Question2	DCB		"2. I look outside for motivation to act, change, or interact.",0

Question3	DCB		"3. I learn via direct observation.",0
Question4	DCB		"4. I learn via practical applications.",0

Question5	DCB		"5. Less expensive and faster is the way to go.",0
Question6	DCB		"6. Thinking from the mind is better than thinking from the heart.",0

Question7	DCB		"7. A clear-and-cut process or a one more leaned towards adaptability.",0
Question8	DCB		"8. Following a process is better than thinking in the moment.",0

;Choices per question
Yes 		DCB "A. Yes",0 ;ESTJ
Unsure 		DCB "B. Unsure",0 ;Unknown
No 			DCB "C. No",0 ;INFP
;Too close to call
TooClose	DCB "(Too close to call.)",0
;Invalid response
invalidChoice DCB "Invalid choice. Please try again.",0
;Goodbye Message
Bye	 DCB 	"Thank you for taking the test! Goodbye now.",0
;Repeat
List DCB "These are your choices: ",0
Repeat DCB "Would you like to repeat for different answer choices (Y/N)? ",0
;Time Message
TimeT DCB    "Time took to complete this: ",0
TimeP DCB "0.01 s",0
;Decision
Decision DCB "You are: ",0
;Score
Score DCB "Score = ",0
;>>>>>   end constants here <<<<<		
            ALIGN
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
String		SPACE	MAX_STRING	;String array variable
	ALIGN
Choices		SPACE 	10			;Choice array variable
	ALIGN
RunStopWatch SPACE 1			;RunStopWatch 
	ALIGN
Count SPACE 4					;Count
;>>>>>   end variables here <<<<<
            ALIGN
            END