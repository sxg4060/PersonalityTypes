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
			IMPORT PIT_ISR
			IMPORT Init_PIT_IRQ
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
            CPSID   I
;KL46 system startup with 48-MHz system clock
            BL      Startup
;---------------------------------------------------------------
;>>>>> begin main program code <<<<<

			BL Init_UART0_IRQ		;Initialize UART0 for serial driver
			BL Init_PIT_IRQ			;Initialize PIT Timer
			BL GREEN_ON
			BL GREEN_OFF
			BL RED_ON
			BL RED_OFF
			BL BOTH_ON
			BL BOTH_OFF
			CPSIE I					;Unmask interrupts from KL46 devices
;----------------------------------------------------------------
			MOVS R2,#0				;Initialize counter
			LDR R0,=Welcome			;Load the welcome message into R0
			MOVS R5,#MAX_STRING		;Load in a buffer capacity for the string
			BL PutStringSB			;Display the welcome message on the terminal
			BL CRLF					;Carriage Return and Line Feed (equivalent to hitting the enter key)
			;First Question
			LDR R0,=Question1		;Load the first question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			;Initializing Timer here
			LDR R7,=RunStopWatch	;Load in stop watch boolean
			MOVS R6,#1				;Load a 1 into R6 to set stop watch boolean
			STRB R6,[R7,#0]			;Move a one into the stop watch to let the count decrement
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed (equivalent to hitting the enter key)
			;Second Question
			LDR R0,=Question2				;Load the first question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed (equivalent to hitting the enter key)
			;Third Question
			LDR R0,=Question3				;Load the second question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed (equivalent to hitting the enter key)
			;Fourth Question
			LDR R0,=Question4				;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Fifth Question
			LDR R0,=Question5				;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Sixth Question
			LDR R0,=Question6				;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Seventh Question
			LDR R0,=Question7				;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Eigth Question
			LDR R0,=Question8				;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Ninth Question
			LDR R0,=Question9				;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Tenth Question
			LDR R0,=Question10				;Load the third question into R0
			BL PutStringSB			;Display the first question
			BL CRLF 				;Enter Key
			BL DisplayChoices		;Display the choices for the user
			LDR R1,=Choices			;Load in the memory address of Choice
			BL GetChar			;Get a character from the user
			BL PutChar
			BL CheckChoices			;Check to see if choice was valid and convert it
			BL CRLF					;Carriage Return and Line Feed
			;Give choice
			BL Decide				;Decide upon the personality type the user is
			;Stop Counter
			LDR R7,=RunStopWatch	;Load in stop watch boolean
			MOVS R6,#0
			STRB R6,[R7,#0]
			;Give total time it took to take the test
			BL CRLF
			LDR R0,=Time
			MOVS R1,R5				;
			BL PutStringSB			;Display time message
			LDR R7,=Count			;Load count
			LDR R0,[R7,#0]			;Load value of count into R0
			BL PutNumU				;Display time it took to finish the test
			MOVS R6,#0
			STR R6,[R7,#0]
;>>>>>   end main program code <<<<<
;Stay here
			ENDP 
			LTORG	
;----------------------------------------------------------------------------------
;>>>>> begin subroutine code <<<<<
CRLF				PROC {R0-R13},{}
					PUSH {R0,LR}
					MOVS R0,#CR
					BL PutChar
					MOVS R0,#LF
					BL PutChar
					POP {R0,PC}
					ENDP
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
			BL PutChar		;Display the character on the terminal
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
			BL PutChar			;Print the value popped
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
			LDR R0,=DS			;Load Strongly Disagree choice
			BL PutStringSB		;Display the choice
			BL CRLF				;Enter Key
			LDR R0,=DM			;Load Disagree moderately
			BL PutStringSB		;Display the choice
			BL CRLF				;Enter Key
			LDR R0,=DL			;Load Disagree a little
			BL PutStringSB		;Display the choice
			BL CRLF				;Enter Key
			LDR R0,=NAND		;Load neither agree nor disagree prompt
			BL PutStringSB		;Display the choice
			BL CRLF				;Enter Key
			LDR R0,=AL			;Load agree a little prompt
			BL PutStringSB		;Display the choice
			BL CRLF				;Enter Key
			LDR R0,=AM			;Load agree moderately choice
			BL PutStringSB		;Display the choice
			BL CRLF				;Enter Key
			LDR R0,=AS			;Load agree strongly
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
				PUSH {R1}			;Push registers to modify onto stack.
				CMP R0,#'a'			;Compare input to 'a'
				BHS checktheZ		;Checks if input is less than z
				B endCheckChoices	;If it is not zero, then
checktheZ		CMP R0,#'z'		 	;Compare input to 'z'
				BLS validLetter	 	;It's valid if in the range
				BHS endCheckChoices	;If input > 'z,' end the checker
validLetter		SUBS R0,R0,#0x20 	;Convert to ASCII
				STRB R0,[R1,#0]		;Store answer choice into memory
				ADDS R1,R1,#1		;Increment pointer
endCheckChoices POP {R1}			;Pop saved registers
				BX LR				;Branch and exchange back to link register
				ENDP				;End the subroutine
;---------------------------------------------------------------
Decide			PROC {R0-R13},{}
;This subroutine gives the user their personality type
;Inputs:
;R0 = M[choices]
;R1 = Score
;R2 = Counter for Size of Array
;Outputs:
;R0 = Your personality type
				PUSH {LR}
				MOVS R2,#0
DecideLoop		CMP R2,#10
				BEQ EndDecide
				LDRB R3,[R0,#0]
				ADDS R2,R2,#1
				CMP R3,#'A'
				BEQ NoIncrement
				CMP R3,#'B'
				BEQ Increment
				CMP R3,#'C'
				BEQ Increment
				CMP R3,#'D'
				BEQ NoIncrement
				CMP R3,#'E'
				BEQ Increment
				CMP R3,#'F'
				BEQ Increment
				CMP R3,#'G'
				BEQ NoIncrement
NoIncrement		B DecideLoop
Increment		ADDS R1,R1,#1
EndDecide		POP {PC}
				ENDP
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
Question1	DCB		"I see myself as extraverted, enthusiatic.",0
Question2	DCB		"I see myself as critical, quarrelsome.",0
Question3	DCB		"I see myself as dependable, self-disciplined.",0
Question4	DCB		"I see myself as anxious, easily upset.",0
Question5	DCB		"I see myself as open to new experiences, complex.",0
Question6	DCB		"I see myself as reserved, quiet.",0
Question7	DCB		"I see myself as sympathetic, warm.",0
Question8	DCB		"I see myself as disorganized, careless.",0
Question9	DCB		"I see myself as calm, emotionally stable.",0
Question10  DCB		"I see myself as conventional, uncreative.",0
;Choices per question
DS	DCB 	"A: Disagree Strongly",0
DM	DCB 	"B: Disagree Moderately",0
DL	DCB		"C: Disagree a little",0
NAND DCB 	"D: Neither agree nor diagree",0
AL DCB		"E: Agree a little",0
AM DCB 		"F: Agree moderately",0
AS DCB 		"G: Agree strongly",0
;Personality Types
ISTJ DCB 	"ISTJ - Logistician",0
INFJ DCB 	"INFJ - Advocate",0
INFP DCB 	"INFP - Mediator",0
INTJ DCB 	"INTJ - Architect",0
INTP DCB 	"INTP - Logician",0
ISTP DCB 	"ISTP - Virtuoso",0
ISFJ DCB 	"ISFJ - Defender",0
ISFP DCB 	"ISFP - Adventurer",0
ENTJ DCB 	"ENTJ - Commander",0
ENTP DCB 	"ENTP - Debater",0
ENFJ DCB 	"ENFJ - Protagonist",0
ENFP DCB 	"ENFP - Campaigner",0
ESFJ DCB 	"ESFJ - Consul",0
ESTJ DCB 	"ESTJ - Executive",0
ESTP DCB 	"ESTP - Entrepreneur",0
ESFP DCB 	"ESFP - Entertainer",0
;Goodbye Message
Bye	 DCB 	"Thank you for taking the test! Goodbye now.",0
;Time Message
Time DCB    "Time took to complete this: ",0
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