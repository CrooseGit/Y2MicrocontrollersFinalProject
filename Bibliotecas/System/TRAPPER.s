;-----------------------------------------------------
; Library for handling traps
; R. Cruise
; Version 1.0
; 24 February 2025
;
;
; Last modified: 09/05/25 
;
; Known bugs: None.
;
; Dependencies: LCD.s, UTIL.s, TIMER.s, BUTTONS.s, KEYPAD.s, EXT_I_HANDLER.s, E_CALL_HANDLER.s, BUZZER.s
;-----------------------------------------------------


; Trap Handler:
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TRAPPER
            CSRRW   SP, MSCRATCH, SP                ; Moves user stack pointer into MSCRATCH, and Machine stack pointer from MSCRATCH into SP.
            ; Preserve Registers: --------------------------------------------
            ; Preserves only the registers used in this file, its up to the ECALL and interrupt handler to sort themselves out.
            ADDI    SP, SP, 4*3
            SW      RA, -4*2[SP]
            SW      T0, -4*1[SP]
            SW      T1, [SP]
            ; ----------------------------------------------------------------

            CSRR    T0, MCAUSE                  ; Read why we came here
            LI      T1, 8                       ; User ECALL cause code
            BEQ     T0, T1, ECALL_HANDLER       ; Is it a software interrupt (system call)?
            BLTZ    T0, EXTERNAL_I_HANDLER      ; Is it a hardware interrupt?

            ; ... space to add other interrupt sources


TRAPPER_EXIT
            ; Restore Registers: --------------------------------------------
            LW      RA, -4*2[SP]
            LW      T0, -4*1[SP]
            LW      T1, [SP]
            SUBI    SP, SP, 4*3
            ; ----------------------------------------------------------------
            CSRRW   SP, MSCRATCH, SP            ; Swaps the user stack pointer back into SP, etc.

            MRET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

