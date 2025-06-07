;-----------------------------------------------------
; Library for interfacing with the Button
; R. Cruise
; Version 1.0
; 28 February 2025
;
; Functions:
; - BUTTON_READ
;
; The functions with names not beginning "BUTTON_" are for internal use within the library.
;
; Last modified: 09/05/25 
;
; Known bugs: None.
; Dependencies: None.
;-----------------------------------------------------

; Useful Macros: -------------------------------------
BUTTON_ADDR          EQU     0x0001_0001
; ----------------------------------------------------


; BUTTON_READ ()
; Reads data from button map returns the value read in A0: ()...._ 1111 means all the buttons are pressed etc)
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
BUTTON_READ

            LI      A0, BUTTON_ADDR
            LBU     A0, [A0]

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

