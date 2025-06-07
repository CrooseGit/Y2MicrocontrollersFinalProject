;-----------------------------------------------------
; Library for interfacing with the LCD
; R. Cruise
; Version 1.0
; 11 February 2025
;
; Functions:
; - LCD_P_STRING: For writing a string to the LCD
; - LCD_P_CHAR: For writing a single character to the LCD
; - LCD_CLEAR: For clearing the display of the LCD
; - LCD_P_BCD: For writing a many digit integer to the LCD
;
; The functions with names not beginning "LCD_" are for internal use within the library.
;
; Last modified: 09/05/25
;
; Known bugs: None.
; Dependencies: UTIL.s
;-----------------------------------------------------


; Useful Macros: -------------------------------------
LCD_ADDR        EQU     0x00010100
;   LCD Bit Patterns: ---------------
BACK_LIGHT      EQU     (0b1 << 11)
ENABLE          EQU     (0b1 << 10)
RS_DATA_nCTRL   EQU     (0b1 << 9)      ; Register select bit. Data when high, control when low.
READ_nWRITE     EQU     (0b1 << 8)      ; Read / write bit. Read when high, write when low
STATUS          EQU     (0b1 << 7)
CLEAR           EQU     (0b1)
;   ---------------------------------
; ----------------------------------------------------


; LCD_P_STRING (A0: String Pointer)
; Writes a string to the LCD
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
LCD_P_STRING
            ; Preserve Registers: --------------------------------------------
            ADDI    SP, SP, 12                  ; Increment SP by 3 words
            SW      RA, -8[SP]                  ; Return Address
            SW      A0, -4[SP]                  ; A0: Argument containing address of string
            SW      S0, [SP]                    ; S0: Pointer to the current character in the string
            ; ----------------------------------------------------------------
            MV      S0, A0                      ; Load string pointer into S0
            J       P_ENTRY

P_LOOP      JAL     LCD_P_CHAR                  ; Call print char function with argument in A0
            ADDI    S0, S0, 1                   ; Increment pointer to point at next character
; While loop entry point           
P_ENTRY     LB      A0, [S0]                    ; Load character into A0 (to be passed as an argument)
            BNEZ    A0, P_LOOP

            ; Restore Registers: --------------------------------------------
            LW      S0, [SP]
            LW      A0, -4[SP]
            LW      RA, -8[SP]
            SUBI    SP, SP, 12
            ; ----------------------------------------------------------------

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -          

; LCD_P_BCD (A0: BCD Value)
; Writes a string of numbers to the LCD
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
LCD_P_BCD
            ; Preserve Registers: --------------------------------------------
            ADDI    SP, SP, 20                  ; Increment SP by 3 words
            SW      RA, -16[SP]                 ; Return Address
            SW      A0, -12[SP]                 ; A0: Argument containing BCD value
            SW      S0, -8[SP]                  ; S0: Start index of the nibble
            SW      S1, -4[SP]                  ; S1: Nibble mask
            SW      S2, [SP]                    ; S2: Copy of A0, because it gets overwritten to pass arg to P_CHAR
            ; ----------------------------------------------------------------

            MV      S2, A0                      ; Copy BCD value to S2
            LI      S0, 28                      ; Start index of nibble, will go 28,24,20,16,...
            LI      S1, 0xF                     ; Nibble mask

P_BCD_LOOP  ; Done this way, rather than with a fixed mask and shifting BCD value, because I need to work from the left side of the bcd value to the right, so either way there is two shifts.
            SLL     T0, S1, S0                  ; Shift mask by index --> T0
            AND     T0, S2, T0                  ; Apply mask to BCD to leave single digit. --> T0
            SRL     A0, T0, S0                  ; Apply shift in reverse to fix place value

            ADDI    A0, A0, 48                  ; Convert to ASCII
            JAL     LCD_P_CHAR                  ; Call print char function with argument in A0

            SUBI    S0, S0, 4                   ; Increment index by length of a nibble

            BGEZ    S0, P_BCD_LOOP              ; Index below zero? Stop.

            ; Restore Registers: --------------------------------------------
            LW      S2, [SP]
            LW      S1, -4[SP]
            LW      S0, -8[SP]
            LW      A0, -12[SP]
            LW      RA, -16[SP]
            SUBI    SP, SP, 20
            ; ----------------------------------------------------------------

            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   

; LCD_P_CHAR (A0: ASCII character code)
; Writes a character to the LCD
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
LCD_P_CHAR
            ; Preserve Registers: --------------------------------------------
            ADDI    SP, SP, 8                   ; Increment SP by 2 words
            SW      RA, -4[SP]                  ; Return Address
            SW      A0, [SP]                    ; A0: ASCII character code to be printed, then used to pass argument to delay function.
            ; ----------------------------------------------------------------

            ; Write to Data Register the data in A0
            LI      A1, RS_DATA_nCTRL           ; Specify the data register
            JAL     WRITE_TO_REG                ; Takes arguments A0 and A1 (Data, Register)

            ; Restore Registers: --------------------------------------------
            LW      A0, [SP]
            LW      RA, -4[SP]
            SUBI    SP, SP, 8
            ; ----------------------------------------------------------------
            
            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -             


; LCD_CLEAR ()
; Clears the LCD which resets cursor position to 0
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
LCD_CLEAR
            ; Preserve Registers: --------------------------------------------
            ADDI    SP, SP, 8                   ; Increment SP by 2 words
            SW      RA, -4[SP]                  ; Return Address
            SW      A0, [SP]                    ; A0: Used to contain LCD clear bit pattern
            ; ----------------------------------------------------------------

            ; Write to Data Register the data in A0
            LI      A0, CLEAR                   ; Specify the bit pattern to clear
            LI      A1, 0                       ; Specify the control register
            JAL     WRITE_TO_REG                ; Takes arguments A0 and A1 (Data, Register)

            ; Restore Registers: --------------------------------------------
            LW      A0, [SP]
            LW      RA, -4[SP]
            SUBI    SP, SP, 8
            ; ----------------------------------------------------------------
            
            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -             


; WRITE_TO_REG (A0: pattern to write to register, A1: Register Select (Data/¬Control))
; Writes to either the data or control register on the LCD. This is an internal function, only used within this file
; Note: assumes A1 has the entire bit pattern for the reg select bit e.g. 0001000... not just a boolean.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
WRITE_TO_REG
            ; Preserve Registers: --------------------------------------------
            ADDI    SP, SP, 4*6                 ; Increment SP by 6 words
            SW      RA, -4*5[SP]                ; Return Address
            SW      A0, -4*4[SP]                ; A0: ASCII character code to be printed, then used to pass argument to delay function.
            SW      S0, -4*3[SP]                ; S0: Data to be written to LCD register
            SW      S1, -4*2[SP]                ; S1: LCD address
            SW      S2, -4*1[SP]    
            SW      S3, [SP]                    ; S3: ASCII character code to be printed
            ; ----------------------------------------------------------------

            LI      S1, LCD_ADDR                ; S1 = LCD address
            MV      S3, A0                      ; Save A0 so is not overwritten for delay calls.
            
            ; Repeatedly polls the LCD until it is found to be idle and no longer busy.
            ; ----------------------------------
            LI      S0, BACK_LIGHT              ; 0 out all bits, turn on backlight
            
            ORI     S0, S0, READ_nWRITE         ; Set bit 8 (Read/¬Write) to 1 (control is already 0)

LOOP_WB     ; Polling loop

            ORI     S0, S0, ENABLE              ; Set bit 10 (enable to 1)
            SW      S0, [S1]                    ; Write to LCD

            LI      A0, 20                      ; Enable pulse width
            JAL     DELAY

            LW      S2, [S1]                    ; read from LCD to S2

            ANDI    S0, S0, ~(ENABLE)           ; mask to clear bit 10 (set enable to 0)
            SW      S0, [S1]                    ; Write to LCD

            ANDI    S2, S2, STATUS              ; Mask to get bit 7 (status bit)

            LI      A0, 48                      ; Enable pulse spacing
            JAL     DELAY
            
            BNEZ S2, LOOP_WB                    ; If status bit is 1, then LCD is busy, poll again.
            ; ----------------------------------


            LI      S0, BACK_LIGHT              ; 0 out all bits, turn on backlight

            OR      S0, S0, A1                  ; Sets the register select bit, Read/¬Write bit is already set to 0 for Write

            ANDI    S3, S3, 0xFF                ; Bit mask to discard bits excluding 0-7 to prevent mischief
            OR      S0, S0, S3                  ; Sets the data bits
           
            ORI     S0, S0, ENABLE              ; Set enable to high
            SW      S0, [S1]                    ; Write bit pattern to LCD

            LI      A0, 20                      ; Enable pulse width
            JAL     DELAY

            ANDI    S0, S0, ~(ENABLE)           ; Set enable to low
            SW      S0, [S1]                    ; Write bit pattern to LCD

            ; Restore Registers: --------------------------------------------
            LW      RA, -4*5[SP]                
            LW      A0, -4*4[SP]                
            LW      S0, -4*3[SP]                
            LW      S1, -4*2[SP]                
            LW      S2, -4*1[SP]    
            LW      S3, [SP]                    
            SUBI    SP, SP, 4*6                 ; Decrement SP by 6 words
            ; ----------------------------------------------------------------
            
            RET
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -            

