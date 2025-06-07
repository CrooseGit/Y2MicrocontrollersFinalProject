;-----------------------------------------------------
; Library for handling external interrupts
; R. Cruise
; Version 1.0
; 28 March 2025
;
;
; Last modified: 09/05/25 
;
; Known bugs: None.
;
; Dependencies: UTIL.s, TIMER.s, BUTTONS.s, KEYPAD.s, BUZZER.s, LED.s
;-----------------------------------------------------


; INTERRUPT RELATED MACROS: -------------
INTERRUPT_REQ_O     EQU     0x08
BTN_REQ_BIT         EQU     2
INTERRUPT_EDGE_O    EQU     0x10
INTERRUPT_TMR_BIT   EQU     4
INTERRUPT_ADDR      EQU     0x0001_0400
INTERRUPT_EN_O      EQU     0x04
INTERRUPT_BTN_BIT   EQU     5
INTERRUPT_BZR_BIT   EQU     0
INTERRUPT_MODE_O    EQU     0x0C
; ---------------------------------------

; Registers are preserved when and where they are used, the only exceptions being T0, T1 and RA as the user registers were already preserved in the trap handler

; External (hardware) interrupt handler
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
EXTERNAL_I_HANDLER
            ; Preserve Registers: --------------------------------------------
            ; All registers that are used in these interrupt routines, and that could be used (and not expected to be preserved) subsequent function calls should be preserved.
            ; This includes all temp registers, RA, and all argument registers.
            ; This potentially could lead to preserving registers that are not used, for example I don't think T5 is used anywhere, but the minor performance hit and tiniest of a fraction of a second wasted by doing this
            ; ... amounts to no time in comparison to how long it would take me to find the source of the bug if I was to decide to use T5 when modifying a function 5 calls deep within one of the functions called in this file.
            ADDI    SP, SP, 4*15                    ; Increment SP by 15 words
            SW      RA, -4*14[SP]                   
            SW      A0, -4*13[SP]
            SW      A1, -4*12[SP]
            SW      A2, -4*11[SP]
            SW      A3, -4*10[SP]
            SW      A4, -4*3[SP]
            SW      A5, -4*9[SP]
            SW      A6, -4*8[SP]
            SW      A7, -4*7[SP]
            SW      T0, -4*6[SP]
            SW      T1, -4*5[SP]
            SW      T2, -4*4[SP]
            SW      T3, -4*3[SP]
            SW      T4, -4*2[SP]
            SW      T5, -4*1[SP]
            SW      T6, [SP]
            ; ------------------------------------


            LI  T0, INTERRUPT_ADDR
            LW  T0, INTERRUPT_REQ_O[T0]                 ; Load interrupt requests

            ANDI T1, T0, (0b1 << INTERRUPT_BTN_BIT)
            BNEZ T1, BUTTON_PRESSED                     ; Was the button pressed?
            ANDI T1, T0, (0b1 << INTERRUPT_TMR_BIT)
            BNEZ T1, TIMER_TICKED                       ; Has the timer ticked?
            ANDI T1, T0, (0b1 << INTERRUPT_BZR_BIT)
            BNEZ T1, BUZZER_FINISHED                    ; Has the timer ticked?


;           Space for more interrupts to be added.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


; Handler exit routine
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
EXTERNAL_I_HANDLER_EXIT 
            ; Restore argument registers --------           
            LW      RA, -4*14[SP]                   
            LW      A0, -4*13[SP]
            LW      A1, -4*12[SP]
            LW      A2, -4*11[SP]
            LW      A3, -4*10[SP]
            LW      A4, -4*3[SP]
            LW      A5, -4*9[SP]
            LW      A6, -4*8[SP]
            LW      A7, -4*7[SP]
            LW      T0, -4*6[SP]
            LW      T1, -4*5[SP]
            LW      T2, -4*4[SP]
            LW      T3, -4*3[SP]
            LW      T4, -4*2[SP]
            LW      T5, -4*1[SP]
            LW      T6, [SP]
            SUBI    SP, SP, 4*15                    ; Increment SP by 15 words
            ; ------------------------------------

            J       TRAPPER_EXIT
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


; BUTTON_PRESSED() ---------------------------------------
BUTTON_PRESSED 

            LI  T0, INTERRUPT_ADDR
            LI  T1, (0b1 << INTERRUPT_BTN_BIT)
            SW  T1, INTERRUPT_EDGE_O[T0] ; Clear button sticky bit

            J EXTERNAL_I_HANDLER_EXIT

; --------------------------------------------------------

; TIMER_TICKED() ---------------------------------------
; Interrupt routine for timer, interrupt based keypad debouncing
; Only capable of detecting a single keypress at a time, as this is all that is required by the code that utilises this.
; Also, this isn't set up to allow you to try and jitter click the keys and key 1000 key presses a second, again because its not necessary for this use case, and simplifies the implementation.
TIMER_TICKED

            ; Preserve Registers: ----------------
            ADDI    SP, SP, 4
            SW      A0, [SP]
            ; ------------------------------------

            JAL     TIMER_STICKY_CLEAR                  ; Clears sticky bit in timer

            ; The gist of this is:
            ; Check if the key (or lack thereof) read from the keypad is different from the one read on the last check (0.008s ago) (LAST_READ)
            ; If its different, then consider this a change in intended state and update the LAST_READ, write this value to the stream, and set the flag.
            ; If no difference, simply proceed with no changes.

            JAL     KP_READ_KEY                 ; Reads Keypad into A0

            BLTZ    A0, CONTINUE                ; if it is -1, there was no keypress, update LAST_READ and exit
            
            ; if not -1, and check last read
            LW      T0, LAST_READ               ; Get last reading
            
            BEQ     T0, A0, CONTINUE            ; if last read is the same, then this is a repeat read?  
            
            ; if last read is different, then this is a keypress
            LW      T0, STREAM_ADDR
            SW      A0, [T0]                    ; Store keypress to shared memory

            LW      T0, STREAM_F_ADDR          
            LI      T1, 1
            SW      T1, [T0]                    ; Set flag in shared memory



CONTINUE
            SW      A0, LAST_READ, T0

            ; Restore Registers: ----------------
            LW      A0, [SP]
            SUBI    SP, SP, 4            
            ; ------------------------------------

            J       EXTERNAL_I_HANDLER_EXIT

; --------------------------------------------------------

; BUZZER_FINISHED() --------------------------------------
BUZZER_FINISHED ; Interrupt handler for the buzzer, triggered when the buzzer has finished playing a note.

            ; Preserve Registers: ----------------
            ADDI    SP, SP, 4
            SW      A0, [SP]
            ; ------------------------------------
            ; Clear leds
            MV  A0, ZERO
            JAL WRITE_TO_LEDS

            JAL     BUZZER_CLEAR_INTRPT
            LW      T0, NEXT_NOTE_ADDR
            LBU     A0, [T0]        ; Load Note
            LBU     A1, 1[T0]       ; Load Duration
            
            
            ; Is it finished?
            LI      T1, EOF
            BEQ     T1, A0, EXTERNAL_I_HANDLER_EXIT

            ; Turn on lights
            JAL     WRITE_TO_LEDS
            
            JAL     BUZZER_BUZZ

            LA      T1, NEXT_NOTE_ADDR
            LW      T0, [T1]
            ADDI    T0, T0, 2       ; Increase pointer
            SW      T0, [T1]

            ; Restore Registers: ----------------
            LW      A0, [SP]
            SUBI    SP, SP, 4            
            ; ------------------------------------

            J EXTERNAL_I_HANDLER_EXIT

; --------------------------------------------------------


; Keystream Variables ---------
STREAM_ADDR         DEFW    0
STREAM_F_ADDR       DEFW    0
LAST_READ           DEFW   -1


