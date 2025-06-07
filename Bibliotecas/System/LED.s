;-----------------------------------------------------
; Library for interfacing with the LEDS
; R. Cruise
; Version 1.0
; 09 May 2025
;
; Functions:
; - WRITE_TO_LEDS
;
; Last modified: 09/05/25 
;
; Known bugs: None.
; Dependencies: None.
;-----------------------------------------------------

; Useful Macros: -------------------------------------
LED_ADDR    EQU     0x0001_0000
; ----------------------------------------------------


; WRITE_TO_LEDS (Pattern: A0)
; Does what it says on the tin.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
WRITE_TO_LEDS
            LI      T0, LED_ADDR
            SB      A0, [T0]
            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    
