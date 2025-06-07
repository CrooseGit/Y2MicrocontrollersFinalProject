;-----------------------------------------------------
; Library for interfacing the keypad when placed in the LEFT expansion slot
; R. Cruise
; Version 1.0
; 14 March 2025 (PI day, wooo)
;
; Functions:
; - KP_READ_KEY
;
; Last modified: 09/05/25 
;
; Known bugs: None.
; Dependencies: None.
;-----------------------------------------------------

; Useful Macros: -------------------------------------
KEYPAD_ADDR         EQU     0x0001_0300
KP_DIRECTION_O      EQU     0x04
KP_CLEAR_O          EQU     0x08
KP_SET_O            EQU     0x0C
KP_DIRECTION_PTN    EQU     0xFFFF_F8FF
KP_INPUT_MSK        EQU     0x0000_F000
SCAN_DELAY          EQU     10
; ----------------------------------------------------

; KP_INIT ()
; Initialises the keypad ready to be read from by setting pin directions
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
KP_INIT
            ; Set directions, for pins
            LI      T1, KEYPAD_ADDR
            LI      T0, KP_DIRECTION_PTN
            SW      T0, KP_DIRECTION_O[T1]

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

; KP_READ_KEY ()
; Checks to see if any key has been pressed. Returns value in A0, is -1 if no press
; Only capable of detecting a single key press at a time, by design. My user code only needs a single key at a time.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
KP_READ_KEY

            ; Preserve Registers: --------------------------------------------
            ADDI    SP, SP, 4*6                     ; Increment SP by 6 words  
            SW      S4, -4*5[SP]          
            SW      S0, -4*4[SP]
            SW      S1, -4*3[SP]
            SW      S2, -4*2[SP]
            SW      S3, -4*1[SP]
            SW      RA, [SP]                        ; Return Address
            ; ----------------------------------------------------------------

            ; Reading from keyboard
            ; Set the following in direction
            ; - key lanes (output): 8,9,10
            ; - input: 12, 13, 14, 15 (set all remaining to input also)
            ; one at a time, set the bit for the each key lane, read bits 12-15, then clear it and move onto next lane

            ; S0: Keypad address, S1: working space, S2: Mask, S3: Column of keypress
            LI      S0, KEYPAD_ADDR
            LI      S2, KP_INPUT_MSK

            ; Clear all data bits
            LI      S1, -1
            SW      S1, KP_CLEAR_O[S0]

            LI      S4, (0b1 << 8)               ; First lane bit mask
            LI      S3, 0                        ; First lane column no.
            ; Could derive one from the other and save a register, but that involves some manipulation, which results in more instructions than preserving and extra register

SCAN_LOOP           
            ; Write to key lane -------
            ;LI      S1, (0b1 << 8)
            SW      S4, KP_SET_O[S0]
            
            ; Allows for propagation delay
            LI      A0, SCAN_DELAY              
            JAL     DELAY

            ; Read data into S1
            LW      S1, [S0]

            ; Mask input to get only matrix input bits
            AND     S1, S1, S2

            BNEZ    S1, KEY_PRESSED

            ; Clear data written to lane 1
            ;LI      S1, (0b1 << 8)
            SW      S4, KP_CLEAR_O[S0]
            ; ---------------------------

            SLLI    S4, S4, 1                   ; Shift so mask is ready for next lane
            ADDI    S3, S3, 1                   ; Increment Column number
            LI      S1, 3         
            BLTU    S3, S1, SCAN_LOOP
            
            ; No key pressed
            LI      A0, -1
            J       READ_KEY_END

KEY_PRESSED ; Label to be jumped to if keypress is detected, works out what the key is and returns. S3: column, S1: 2^row (0001,0010,0100,1000)

            ; First, identify index of set bit in S1
            SLLI    S0, S1, 15  ; Shift bits to be one off the msb i.e 0ABCD 0000 ... where abcd are the bits of interest
            LI      S1, 4       ; Index of set bit / row

LOG_2_LP    
            SLLI    S0, S0, 1           ; Move next bit into the sign bit position
            SUBI    S1, S1, 1           ; Decrement index
            BGTZ    S0, LOG_2_LP        ; Check if sign bit is set, if not, keep looping

            ; Use keypad map to return pressed key S1: row
            LA S0, KEYPAD_MAP

            SLLI    S3, S3, 2   ; S3 = index of start of column
            ADD     S0, S0, S3  ; S0 = address of start of column
            ADD     S0, S0, S1  ; S0 = address of start of byte

            LBU     A0, [S0]    ; Fingers cross, should load relevant byte from table. God willing.

READ_KEY_END
            ; Restore Registers: --------------------------------------------           
            LW      S4, -4*5[SP]
            LW      S0, -4*4[SP]
            LW      S1, -4*3[SP]
            LW      S2, -4*2[SP]
            LW      S3, -4*1[SP]
            LW      RA, [SP]                     ; Return Address                            
            SUBI    SP, SP, 4*6                  ; Decrement SP by 6 words
            ; ----------------------------------------------------------------
            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

            ; Col 0
KEYPAD_MAP  DEFB '*'
            DEFB 7
            DEFB 4
            DEFB 1
            ; Col 1
            DEFB 0
            DEFB 8
            DEFB 5
            DEFB 2                    
            ; Col 2
            DEFB '#'
            DEFB 9
            DEFB 6
            DEFB 3          