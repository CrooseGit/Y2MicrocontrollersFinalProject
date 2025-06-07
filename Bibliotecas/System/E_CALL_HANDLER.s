;-----------------------------------------------------
; Library for handling system calls
; R. Cruise
; Version 1.0
; 28 March 2025
;
;
; Last modified: 09/05/25 
;
; Known bugs: None.
;
; Dependencies: LCD.s, UTIL.s, TIMER.s, BUTTONS.s, KEYPAD.s, TRAPPER.s, BUZZER.s
;-----------------------------------------------------

; Sys call handler
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
ECALL_HANDLER       ; A7: ECALL index, A0: Argument

            ; Should only preserve save registers if used, Temp & arg registers are expected to be invalidated when a sys call is called (or any function). And RA has already been preserved in TRAPPER.s.
            ; Consequentially, in this circumstance, no registers need preserving.
           

            LI      T0, ECALL_OOB               ; Check ECALL index is in range
            BGEU    A7, T0, ECALL_X             ; Out of range index defaults to ECALL_X
            LA      T0, ECALL_JUMP              ; Load jump table address
            SLLI    T1, A7, 2                   ; Calculate index (in words)
            ADD     T0, T0, T1                  ;
            LW      T0, [T0]                    ; Load address of service routine
            JALR    T0                          ; and jump to it, return here after

            ;J       ECALL_HANDLER_END          ; Deliberately commented as the target is the next instruction.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

; Sys call handler exit code
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
ECALL_HANDLER_END ; ---------------------------------------  

            CSRRW   T0, MEPC, T0                ; Load address of trapping instruction
            ADDI    T0, T0, 4                   ; Increment to point at next instruction (don't want to execute trapping instruction again.)
            CSRRW   T0, MEPC, T0                ; Store address to return to back to MEPCx`
            J       TRAPPER_EXIT
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

; ECALL Routines:
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
ECALL_0 ; Terminate program: -------------------------------------
            J       .
; ----------------------------------------------------------------
ECALL_3 ; Print Number to standard output: -----------------------
        ; A0: Number 
            
            JAL     UINT_TO_BCD                 ; Converts A0 to BCD, stores to A0
            JAL     LCD_P_BCD                   ; Prints BCD value to LCD

            J       ECALL_HANDLER_END           ; Could use RET, but then would have to save and restore RA, and as we know where we are returning to, there is no need.
                                                ; Could also use another LR, X5 is suggested by the ABI I hear, but this works fine.

; Sys call used by the user that takes a pair of addresses, into which the debounced key information will appear. Allowing user code to take key inputs.
ECALL_15 ; Read keystream: -------------------------
        ; A0: pointer to location in user space to write keypresses to
        ; A1: pointer to location in user space to flag changes

            JAL     KP_INIT                     ; Setup keypad

            SW      A0, STREAM_ADDR, T0         ; Save user space addresses that hold the key and flag
            SW      A1, STREAM_F_ADDR, T0
            JAL     TIMER_INIT                  
            LI      A0, (8000 - 1)              ; 8000 micro seconds = 0.008 seconds, 125Hz (standard sample rate for old keyboards)
            JAL     TIMER_MODULUS_ENABLE
            JAL     TIMER_INTERRUPT_ENABLE            
            JAL     TIMER_START

            ; Dynamically Linking tasks to interrupt handlers would be nice, but is considerable work at this stage. A nice to have if time was not a constraint.
            
            J       ECALL_HANDLER_END     
                  
ECALL_X ; Default handler, do nothing.
            J       ECALL_HANDLER_END
; ----------------------------------------------------------------
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


; _________________________________________________________________________________________________________________
; Jump table of ECALLs                                                                                     | INDEX
; _________________________________________________________________________________________________________________
ECALL_JUMP  DEFW ECALL_0 ; Stop                                                                            |  00                                                                                
JT_PCR      DEFW LCD_P_CHAR ; Print Char, A0: Character code                                               |  01                            
JT_PST      DEFW LCD_P_STRING ; Print String, A0: String pointer (Must include null terminator)            |  02                                                            
JT_PNM      DEFW ECALL_3 ; Print Number                                                                    |  03    
JT_LCL      DEFW LCD_CLEAR ; Clear Std output                                                              |  04            
JT_TRD      DEFW TIMER_READ ; Read from timer                                                              |  05            
JT_TIN      DEFW TIMER_INIT ; Initialise timer                                                             |  06            
JT_TST      DEFW TIMER_START ; Start timer                                                                 |  07        
JT_TME      DEFW TIMER_MODULUS_ENABLE ; Enable modulus mode timer and set limit                            |  08                                                                                                                                                           
JT_BRD      DEFW BUTTON_READ ; Read from button                                                            |  09            
JT_TPA      DEFW TIMER_STOP ; Stop the timer                                                               |  0A           
JT_TRC      DEFW TIMER_READ_CTRL ; read from timer control reg                                             |  0B                           
JT_TSC      DEFW TIMER_STICKY_CLEAR ; clear the timer sticky bit                                           |  0C                               
JT_KRK      DEFW KP_READ_KEY ; Read keypress                                                               |  0D           
JT_RKS      DEFW ECALL_15 ; Read keystream                                                                 |  0E       
JT_BBZ      DEFW BUZZER_BUZZ ; Plays note A0, for A1 thousandths of a second (Note: A0, Duration: A1)      |  0F                                                                   
JT_BPT      DEFW BUZZER_PLAY_TUNE ; (A0: Address of next note)                                             |  10  
E_INVALID   ; Out of bounds label for auto ECALL_OOB calculation                                           |  11 = ECALL_OOB
; _________________________________________________________________________________________________________________

; ECALL MACROS: -------------------------
; Automatically calculates index into table for easier maintenance
E_STOP              EQU     (ECALL_JUMP - ECALL_JUMP) /4
E_PRINT_CHAR        EQU     (JT_PCR - ECALL_JUMP) / 4 
E_PRINT_STRING      EQU     (JT_PST - ECALL_JUMP) / 4
E_PRINT_NUM         EQU     (JT_PNM - ECALL_JUMP) / 4
E_CLEAR             EQU     (JT_LCL - ECALL_JUMP) / 4
E_T_READ            EQU     (JT_TRD - ECALL_JUMP) / 4
E_T_INIT            EQU     (JT_TIN - ECALL_JUMP) / 4
E_T_START           EQU     (JT_TST - ECALL_JUMP) / 4
E_T_EN_MOD          EQU     (JT_TME - ECALL_JUMP) / 4
E_B_READ            EQU     (JT_BRD - ECALL_JUMP) / 4
E_T_STOP            EQU     (JT_TPA - ECALL_JUMP) / 4
E_T_READ_CTRL       EQU     (JT_TRC - ECALL_JUMP) / 4
E_T_CLR_STICKY      EQU     (JT_TSC - ECALL_JUMP) / 4
E_K_READ_KEY        EQU     (JT_KRK - ECALL_JUMP) / 4
E_K_READ_KEY_STREAM EQU     (JT_RKS - ECALL_JUMP) / 4
E_B_BUZZ            EQU     (JT_BBZ - ECALL_JUMP) / 4
E_B_PLAY_TUNE       EQU     (JT_BPT - ECALL_JUMP) / 4
ECALL_OOB           EQU     (E_INVALID - ECALL_JUMP) / 4      ; Out of bounds index. The greatest ECALL index is one less than this.
; ---------------------------------------
