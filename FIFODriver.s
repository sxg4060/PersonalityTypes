					TTL FifoDriver
;****************************************************************
;Description: Driver for Queue Operations
;the user.
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
            OPT  1   ;Turn on listing
;****************************************************************
;Queue Management Record
IN_PTR EQU 0	;Buffer address for next enqueue
OUT_PTR EQU 4	;Buffer address for next dequeue
BUF_STRT EQU 8	;Lowest buffer address
BUF_PAST EQU 12	;First address past end of buffer
BUF_SIZE EQU 16	;Size of buffer
NUM_ENQD EQU 17	;Number that was enqueued.
;Queue Structure Sizes
Q_BUF_SZ EQU 4	;Room for 80 characters
Q_REC_SZ EQU 18 ;Management record size
;*****************************************************************
        EXPORT InitQueue
        EXPORT Dequeue
        EXPORT Enqueue
        EXPORT PutStringSB
        EXPORT PutNumHex
        IMPORT PutChar
        AREA FifoCode,CODE,READONLY
;*****************************************************************
InitQueue	PROC {R0-R13},{}
;This subroutine initializes the queue record structure at the address in R1 
;for the empty queue buffer at the address in R0 of size, 
;(i.e., character capacity), given in R2.

			PUSH {R0-R2,LR}			;Push saved registers
			;LDR R0,=QBuffer			;Load R1 with &QBuffer
			;LDR R1,=QRecord			;Load R0 with &QRecord
			STR R0,[R1,#IN_PTR]		;Store QBuffer's In_ptr in the QRecord
			STR R0,[R1,#OUT_PTR]	;Store QBuffer's Out_ptr in the QRecord
			STR R0,[R1,#BUF_STRT]	;Store QBuffer's starting address in QRecord
			MOVS R2,#Q_BUF_SZ		;Move the Queue buffer size value into R2
			ADDS R0,R0,R2			;Add the &QBuffer and buffer size
			STR R0,[R1,#BUF_PAST]	;Store sum of previous command in QRecord
			STRB R2,[R1,#BUF_SIZE]	;Store byte value of size in QRecord
			MOVS R0,#0				;Move 0 into R0
			STRB R0,[R1,#NUM_ENQD]	;Store Byte 0 in QRecord for number currently enqueued
			POP {R0-R2,PC}				;Pop saved registers				
			ENDP					;End Subroutine
;-------------------------------------------------------------------
Dequeue		PROC {R0-R13},{}
;This subroutine is responsible for getting a character from
;the queue to remove it; if the queue is empty, dequeue fails
;and the carry flag is set to 1. If the queue is not empty, get 
;address of the out_ptr and remove that entry from the queue (Clear C
;flag)
;Input: 
;R1 = &Queue Record
;Outputs: 
;R0 = Character dequeued
;APSR C Flag
;Modify: R0,APSR
;All other register remain unchanged on return
			PUSH {R1-R7}			;Store registers other than R0 and APSR in stack
			LDRB R2,[R1,#NUM_ENQD]	;Load byte-value of the current amount of numbers engueued into R0
            CMP R2,#0				;Compare numbers enqueued to '0'
            BEQ Failure				;If there are no numbers enqueued, branch to failure
			LDR R3,[R1,#OUT_PTR]	;Load address of out pointer into R3
			LDRB R0,[R3,#0]			;Load the value of the Out_ptr into R0 as the value to dequeue
			ADDS R3,R3,#1			;Increment the out pointer by one to move it forward
			STR R3,[R1,#OUT_PTR]	;Store new out pointer value 
			SUBS R2,R2,#1			;decrement numbers enqueued by one
			STRB R2,[R1,#NUM_ENQD]	;Store new num_enqd value
			LDR R4,[R1,#BUF_PAST]	;Load the value of the Buffer size into R4
			CMP R3,R4				;Compare the out pointer to the size of the Queue Buffer
			BHS Circulate			;If out pointer points outside queue buffer, then adjust outpointer to start of queue
ClearCarry	MRS R6,APSR				; Move to special register from R3 
			LDR R7,=0x20000000		;Load R6 with mask to BICS with
			BICS R6,R6,R7			;Bit clear R5 and R6 to reset carry flag without changing the other flags
			MSR APSR,R6				;Move to R3 from special register
			B EndDequeue			;End the dequeue process
Circulate	LDR R5,[R1,#BUF_STRT]	;Load Start of buffer into R5
			MOVS R3,R5              ;Set pointer into R0
			STR R3,[R1,#OUT_PTR]	;Store new out_ptr in R3
			B ClearCarry			;Set Carry to show successful dequeue
Failure		MRS R6,APSR				;Move to special register from R3
			LDR R7,=0x20000000		;Load R4 with 0x20000000 to set the carry flag without affecting other flags
			ORRS R6,R6,R7			;R3 = R3 | R4, will set off the carry bit (20000000 | 00000000 = 20000000)
			MSR APSR,R6				;Move to R3 from special register
			B EndDequeue			;Branch back to the EndWhile Label to reset the flag and prepare for next inputs
EndDequeue	POP {R1-R7}				;Restore pushed register
			BX LR					;Branch and exhange with link register
			ENDP					;End the subroutine
;----------------------------------------------------------------
Enqueue		PROC {R0-R13},{}
;If the queue is not full, enqueue a character from R0 to the queue
;and report a success by clearing the C flag. If a failure, set C flag
;Inputs:
;R0 = Character to enqueue
;R1 = Address of queue record
;Outputs:
;APSR C Flag
;Modify; APSR
;All other registers remain unchanged on return
			PUSH {R0-R7}			;Save registers onto stack
			LDRB R2,[R1,#NUM_ENQD]	;Load the number of items enqueued in the queue
			LDRB R3,[R1,#BUF_SIZE]	;Load the value of address of the buffer size into R3		
			CMP R2,R3				;Compare R2 and R3 to see if queue is full
            BEQ QueueIsFull			;Branch to label if queue is full
			LDR R4,[R1,#IN_PTR]		;Load address of IN_PTR into R3
			STRB R0,[R4,#0]			;Store the character to enqueue in R0
            ADDS R2,R2,#1			;Increment number of items in queue
			STRB R2,[R1,#NUM_ENQD]	;Store the new num_enqd into R2
			ADDS R4,R4,#1			;Increment in pointer 
			STR R4,[R1,#IN_PTR]		;Store new in_ptr into R4
			LDR R5,[R1,#BUF_PAST]   ;Load Buffer_past into R5  
            CMP R4,R5				;Compare in_ptr to buffer past address
			BHS CircEnQ				;If they are equal, circulate the in_ptr to the beginning of the queue
ClearCarryEnQ	MRS R6,APSR				; Move to special register from R5 
				LDR R7,=0x20000000		;Load R6 with mask to BICS with
				BICS R6,R6,R7			;Bit clear R5 and R6 to reset carry flag without changing the other flags
				MSR APSR,R6				;Move to R5 from special register
				B EndEnqueue			;End the enqueue process
CircEnQ		    LDR R6,[R1,#BUF_STRT]	;Load the start address of the buffer into R4
                MOVS R4,R6              ;Move R6 into R4
                STR R4,[R1,#IN_PTR]		;Store the new in_pointer into R1
				B ClearCarryEnQ			;Branch to clear the C flag
QueueIsFull		MRS R6,APSR				;Move to special register from R5
				LDR R7,=0x20000000		;Load R6 with 0x20000000 to set the carry flag without affecting other flags
				ORRS R6,R6,R7			;R5 = R5 | R6, will set off the carry bit (20000000 | 00000000 = 20000000)
				MSR APSR,R6				;Move to R5 from special register
				B EndEnqueue			;Branch back to the EndEnqueue Label 
				
EndEnqueue	POP {R0-R7}				;Restore pushed registers
			BX LR					;Branch and exhange with link register
			ENDP					;End the subroutine 
;----------------------------------------------------------------
;----------------------------------------------------------------
PutNumHex   PROC {R0-R13},{}
;This subroutine prints to the terminal screen the text hexadecimal 
;representation of the unsigned word value in R0.  (For example, 
;if R0 contains 0x000012FF, then 000012FF should print on the 
;terminal.  Note:  12FF would notbe acceptable.  Do not use 
;division to determine the hexadecimal digit values.) 
;Inputs: 
;R0 = Unsigned word value to print in hex
;Modify:
;PSR (after return, nothing else)
            PUSH {R0-R7,LR}				;Push registers to save onto stack, as well as link register
			REV R4,R0					;Reverse all the bytes with an outer reverse and inner reverse
			MOVS R5,#0					;Initialize counter to take 
loopH		MOVS R1,#0xF0				;Move 0xF0 into R1 to act as initial mask
			MOVS R2,R4					;Move R4 into R2 for AND cmd. to work
			ANDS R2,R2,R1				;And R1 and R2 to isolate the first nibble of R0
			LSRS R2,R2,#4				;Shift the answer right by 4 bits
			MOVS R3,R2					;Move R2 into R3
			CMP R3,#0x0A				;Compare R3 with 0xA to see if it's above 9
			BHS MoreThanA				;Branch if higher than or equal to MoreThanA
			B NotLetter					;If R3 < 0x0A, then it's not a letter value
MoreThanA	CMP R3,#0x0F				;Compare R3 with 0xF to see if it's between 0xA and 0xF
			BLS LessThanF				;If it is, branch to LessThanF
LessThanF	ADDS R3,R3,#0x37			;Add 0x37 to R3 to get ASCII value
			MOVS R0,R3					;Move R3 into R0 to act as PutChar's input
			BL PutChar					;Call PutChar to display value
			ADDS R5,R5,#1				;Increment counter
			B Return1					;Do not compare against numbers, so branch to Return1
NotLetter	CMP R3,#0x09				;Compare R3 against 0x9 to see if it's a number
			BLS LessThan9				;If R3 < 0x9, then Branch to LessThan9
			B Endloop					;If R3 > 0x9, then R3 is not a number
LessThan9	CMP R3,#0x00				;Compare R3 against 0x0 to see it's in between 0 and 9
			BHS MoreThan0				;If R3 > 0, then Branch to MoreThan0
			B Endloop					;Branch to EndLoop
MoreThan0	ADDS R3,R3,#0x30			;Add 0x30 to R3 to get the ASCII value			
			MOVS R0,R3					;Move ASCII value into R0 to print it
			BL PutChar					;Put the character on the terminal
			ADDS R5,R5,#1				;Increment counter
			B Return1					;Branch to Return1
Return1		LSRS R1,R1,#4				;Shift 0xF0 to become 0x0F for new mask
			MOVS R2,R4					;Move R4 into R2 to prepare for next 
			ANDS R2,R2,R1				;And R4 and R1 again for the remaining nibble of the byte
			MOVS R3,R2					;Move Anded result into R3
			CMP R3,#0x0A				;Compare R3 against 0x0A to see if it's a letter
			BHS MoreThanA2				;If R3 > 0x0A, it may be considered a letter
			B NotLetter2				;If R3 < 0x0A, it is not a letter
MoreThanA2	CMP R3,#0x0F				;Compare R3 against 0x0F to see if it's in range
			BLS LessThanF2				;If R3 < 0x0F, it is a letter
			B Endloop					;If R3 > 0x0F, it is not a hex letter
LessThanF2	ADDS R3,R3,#0x37			;Add 37 to R3 to get ASCII value
			MOVS R0,R3					;Move R3 into R0 as input for PutChar
			BL PutChar					;Call PutChar subroutine
			ADDS R5,R5,#1				;Increment counter
			B Return2					;Return2 will move to Return2 to shift byte 
NotLetter2	CMP R3,#0x09				;Compare R3 against 0x09 to see if it's a number
			BLS LessThan9A				;If R3 < 0x09, it can be considered a number
			B Endloop					;If R3 > 0x09, it is not a number
LessThan9A	CMP R3,#0x00				;Compare R3 against 0 to see if is between 0 and 9
			BHS MoreThan0A				;If R3 > 0x00, it's in the range
			B Endloop					;If R3 < 0x00, it's out of range
MoreThan0A	ADDS R3,R3,#0x30			;Add 0x30 to ASCII value
			MOVS R0,R3					;Move R3 into R0 to print out the character
			BL PutChar					;Display character on terminal
			ADDS R5,R5,#1				;Increment counter
			B Return2					;Branch to Return2
Return2		LSRS R4,R4,#8				;Shift the word right by 8 bits to work on next byte
			CMP R5,#8					;Compare R4 to zero to see if you have fully shifted all the bits
			BNE loopH					;If not equal to zero, then loop again to get the hex value
Endloop		POP {R0-R7,PC}				;Pop R0-R7, as well as PC
			ENDP						;End the subroutine
;----------------------------------------------------------------
PutStringSB PROC {R0-R13},{}
;PutStringSB is a subroutine that displays a string
;on the terminal keyboard from memory starting at 
;the address in R0
;R0 = Initially the memory address of the String put into the terminal
;R1 = Buffer Capacity
;R2 = This Reg. gets R0's contents before calling GetChar, which will overwrite R0
;R3 = Loop Counter
            PUSH {R2,R3,LR}		;Move saced registers
			
			MOV R2,R0			;Move R0 into R2
            MOVS R3,#0			;Initialize counter
WhilePut	LDRB R0,[R2,R3]		;Load value of word's address with offset R3 into R0
            CMP R0,#0			;Compare R0 to Null
            BEQ PutNull			;Branch if R0 = Null (0)
			BL PutChar			;Call PutChar Subroutine
			ADDS R3,R3,#1		;Increment counter
			CMP R3,R1			;Compare loop counter to max_string size
			BHS PutNull			;If counter > string size, then branch to the PutNull
			B WhilePut			;branch back to Beginning of loop
			
PutNull		MOVS R0,#0			;Move a null into R0
			BL PutChar			;Display the character on the terminal
			

;EndWhile    
            POP {R2,R3,PC} 		;Pop saved register         
            ENDP				;End Process
;---------------------------------------------------------------
            END