;-----------------------------------------------------
; Library for interfacing with the Buzzer via my controller
; R. Cruise
; Version 1.0
; 30 April 2025
;
; Functions:
; - BUZZER_BUZZ
; - BUZZER_INIT
; - BUZZER_CLEAR_INTRPT
; - BUZZER_PLAY_TUNE
;
; The functions with names not beginning BUZZER_" are for internal use within the library.
;
; Last modified: 09/05/25 
;
; Known bugs: None.
; Dependencies: None.
;-----------------------------------------------------

; Useful Macros: -------------------------------------
BUZZER_ADDR             EQU     0x0002_0000
BUZZER_INTRPT_CLR_O     EQU     0x04
BUZZER_CONFIG_ADDR      EQU     0x0001_0708
BUZZER_CONFIG_PTN       EQU     0xC0
; ----------------------------------------------------


; BUZZER_BUZZ (Note: A0, Duration: A1)
; Plays note A0, for A1 thousandths of a second
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
BUZZER_BUZZ 
            ;     432 1098 7654 3210
            ;..._.NNN_NNDD_DDDD_DDDD

            SLLI    T0, A0, 10 
            OR      T0, T0, A1
            LI      T1, BUZZER_ADDR
            SW      T0, [T1] 

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

; BUZZER_INIT()
; Configures the buzzer to be controlled by the user expansion module, clears interrupt
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
BUZZER_INIT 
            ; Set buzzer control to user expansion
            LI      T0, BUZZER_CONFIG_ADDR
            LI      T1, BUZZER_CONFIG_PTN
            SW      T1, [T0]

            ; Clear interrupt    
            LI      T0, BUZZER_ADDR
            SW      ZERO, BUZZER_INTRPT_CLR_O[T0]  

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

; BUZZER_CLEAR_INTRPT()
; Clears interrupt from buzzer
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
BUZZER_CLEAR_INTRPT
            ; Clear interrupt    
            LI      T0, BUZZER_ADDR
            SW      ZERO, BUZZER_INTRPT_CLR_O[T0]  

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

; BUZZER_PLAY_TUNE(A0: Address of next note)
; Stores the address of next note, then plays an empty note, when this ends it will trigger the interrupts handler, which will play the remaining notes.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
BUZZER_PLAY_TUNE
            ADDI    SP, SP, 4
            SW      RA, [SP]                    

            LA      T1, NEXT_NOTE_ADDR
            SW      A0, [T1]

            LI      A0, REST
            LI      A1, 1
            JAL     BUZZER_BUZZ

            LW      RA, [SP] 
            SUBI    SP, SP, 4

            RET
             
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


; Buzzer Variables
NEXT_NOTE_ADDR      DEFW    0

; NOTES: ------------------
C_HIGH	        EQU     0x00	
B_HIGH	        EQU     0x01	
Bb_HIGH		    EQU     0x02	
A_HIGH		    EQU     0x03	
GSHARP_HIGH	    EQU     0x04	
G_HIGH	        EQU     0x05	
FSHARP_HIGH	    EQU     0x06	
F_HIGH		    EQU     0x07	
E_HIGH		    EQU     0x08	
Eb_HIGH		    EQU     0x09	
D_HIGH		    EQU     0x0A	
CSHARP_HIGH	    EQU     0x0B	
C_LOW	        EQU     0x0C	
B_LOW		    EQU     0x0D	
Bb_LOW		    EQU     0x0E	
A_LOW		    EQU     0x0F	
GSHARP_LOW	    EQU     0x10	
G_LOW		    EQU     0x11	
FSHARP_LOW      EQU     0x12	
F_LOW		    EQU     0x13	
E_LOW		    EQU     0x14	
Eb_LOW		    EQU     0x15	
D_LOW		    EQU     0x16	
CSHARP_LOW	    EQU     0x17	
C_LOW_LOW	    EQU     0x18
REST            EQU     0xFE
EOF             EQU     0xFF
; -------------------------