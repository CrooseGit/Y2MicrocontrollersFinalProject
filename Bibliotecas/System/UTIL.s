;-----------------------------------------------------
; Utilities Library
; R. Cruise
; Version 1.0
; 11 February 2025
;
; This library contains some general use functions.
; Functions:
; - DELAY
; - UINT_TO_BCD
;
; Last modified: 09/05/25
;
; Known bugs: None
;
;-----------------------------------------------------


; DELAY (A0: number of cycles)
; Loops the given number of times to implement a delay.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
DELAY
; No need to push and pop registers as is a leaf call.            
            MV      T0, A0
DELAY_LOOP   
            SUBI    T0, T0, 1
            BNEZ    T0, DELAY_LOOP
            
            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


; UINT_TO_BCD(A0: Unsigned binary value)
; Convert unsigned binary value in A0 into BCD representation, returned in A0
; Any overflowing digits are generated, but not retained or returned in this
; version.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
UINT_TO_BCD

            LA      T0, DEC_TABLE       ; Point at conversion table
            MV      T1, ZERO            ; Zero accumulator
            LI      T3, 1               ; Termination value
            J       UTB_LOOP_IN         ; Enter loop

UTB_LOOP
            DIVU    T4, A0, T2          ; T4 is next decimal digit
            REMU    A0, A0, T2          ; A0 is the remainder

            ADD     T1, T1, T4          ; Accumulate result
            SLLI    T1, T1, 4           ; Shift accumulator

            ADDI    T0, T0, 4           ; Step pointer

UTB_LOOP_IN
            LW      T2, [T0]            ; Get next divisor
            BNE     T2, T3, UTB_LOOP    ; Termination condition?

UTB_OUT
            ADD     A0, T1, A0          ; Accumulate result to output

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; Defined Memory: -----------------------
DEC_TABLE   DEFW    1000000000, 100000000, 10000000, 1000000
            DEFW    100000, 10000, 1000, 100, 10, 1
; ---------------------------------------
