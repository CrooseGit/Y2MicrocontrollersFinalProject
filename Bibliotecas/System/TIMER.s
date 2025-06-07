;-----------------------------------------------------
; Library for interfacing with the Timer
; R. Cruise
; Version 1.0
; 28 February 2025
;
; This library contains some useful functions for the Timer
; Including:
; - TIMER_READ
; - TIMER_START
; - TIMER_MODULUS_ENABLE
; - TIMER_STOP
; - TIMER_READ_CTRL
; - TIMER_STICKY_CLEAR
;
;
; Last modified: 09/05/25
;
; Known bugs: None.
; Dependencies: None.
;-----------------------------------------------------

; Useful Macros: -------------------------------------
TIMER_ADDR          EQU     0x0001_0200
;   Offsets
MODULUS_O           EQU     0x04
CONTROL_REG_O       EQU     0x0C
CONTROL_SET_O       EQU     0x14
CONTROL_CL_O        EQU     0x10
;   Bit positions
ENABLE_BIT          EQU     0
MODULUS_BIT         EQU     1
STICKY_BIT          EQU     31
INTERRUPT_BIT       EQU     3

; ----------------------------------------------------


; TIMER_READ ()
; Read data from Timer, returns value in A0
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TIMER_READ
            LI      T0, TIMER_ADDR
            LW      A0, [T0]

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    


; TIMER_INIT ()
; Initialises the timer by zeroing out control register. (Will clear any interrupts, and stop timer.)
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TIMER_INIT
            LI      T0, TIMER_ADDR
            SW      ZERO, CONTROL_REG_O[T0]
            ; Doesn't initialise modulus register because what value would it make sense to default to?
            ; Clearing the control reg disables modulus counting anyway, limit should be defined when modulus is enabled.
            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    


; TIMER_START ()
; Starts the timer by setting control register enable bit to 1
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TIMER_START
            LI      T0, TIMER_ADDR
            LI      T1, (0b1 << ENABLE_BIT)
            SW      T1, CONTROL_SET_O[T0]

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

; TIMER_MODULUS_ENABLE (A0: Limit (modulus -1)) (And Limit set)
; Sets timer to use modulus mode by setting control register modulus bit to 1, and sets the limit
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TIMER_MODULUS_ENABLE      
            LI      T0, TIMER_ADDR              ; Set limit
            SW      A0, MODULUS_O[T0]

            LI      T1, (0b1 << MODULUS_BIT)    ; Enable modulus
            SW      T1, CONTROL_SET_O[T0]

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

; TIMER_INTERRUPT_ENABLE ()
; Sets timer to interrupt by setting control register interrupt bit to 1
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TIMER_INTERRUPT_ENABLE
            LI      T0, TIMER_ADDR
            LI      T1, (0b1 << INTERRUPT_BIT)
            SW      T1, CONTROL_SET_O[T0]

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -        

; TIMER_STOP ()
; Stops the timer by setting control register enable bit to 1
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TIMER_STOP
            LI      T0, TIMER_ADDR
            LI      T1, (0b1 << ENABLE_BIT)
            SW      T1, CONTROL_CL_O[T0]

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   

; TIMER_READ_CTRL ()
; Read data from timer control register
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TIMER_READ_CTRL
            LI      T0, TIMER_ADDR
            LW      A0, CONTROL_REG_O[T0]

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; TIMER_STICKY_CLEAR ()
; Clears the sticky bit on the timer using the clear register
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
TIMER_STICKY_CLEAR
            LI      T0, TIMER_ADDR
            LI      T1, (0b1 << STICKY_BIT)
            SW      T1, CONTROL_CL_O[T0]

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   