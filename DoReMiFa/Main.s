;-----------------------------------------------------
; Square waves have never sounded so sweet.
; R. Cruise
; Version 1.0
; 28 April 2025
;
; 
;
; Last modified: 09/05/25 
;
; Known bugs: None
;
; Note: Stacks grow from small to large memory addresses    
;-----------------------------------------------------

; Machine Space: -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
; Program Setup: ------------------------
            ; Initialise exception vectors:
            LA      T0, TRAPPER                 ; Load Trap Handler pointer
            CSRW    MTVEC, T0                   ; Save address in system CSR
            
            ; Initialise System Stack:
            LA      SP, OS_STACK
            CSRW    MSCRATCH, SP                ; Copy ‘machine’ SP for use in handler
            LA      SP, MAIN_STACK              ; Change SP to user space
        
            ; Initialise peripherals
            JAL     BUZZER_INIT
            JAL     LCD_CLEAR

            ; Set interrupt enable bits on controller (enable buzzer controller (user expansion) interrupt)
            LI      T0, INTERRUPT_ADDR
            LI      T1, ((0b1 << INTERRUPT_BZR_BIT) + (0b1 << INTERRUPT_TMR_BIT))
            SW      T1, INTERRUPT_EN_O[T0]

            ; Clear edge register
            LI      T1, -1
            SW      T1, INTERRUPT_EDGE_O[T0]

            ; Set MIE (Machine interrupt enable) to enable interrupts from the interrupt controller
            LI      T0, (0b1 << 11) 
            CSRW    MIE, T0         ; Bit 11 is our external interrupt controller

            ; Set bits in MStatus
            LI      T0, (0b1 << 3)  ; Set bit 3, MIE
            CSRS    MSTATUS, T0
            
            ; Set return mode to user:
            LI      T0, 0x0000_1800             ; Load MPP mask - bits 12 & 11 - MPP is two bits that hold the previous privilege level
            CSRC    MSTATUS, T0                 ; Clear MPP bits in status - effectively saying the previous level was user
            
            ; Set return address to user space:  
            LA      RA, MAIN                    ; Point at user code start
            CSRW    MEPC, RA                    ; Save as ‘return address’

            MRET                                ; ‘Return’ to programme start
; ---------------------------------------

; System stack: -------------------------
ALIGN
OS_STACK   DEFS 500
OS_STACK_TOP
; ---------------------------------------

; System Library Imports ----------------
ALIGN
INCLUDE    ../Bibliotecas/System/TRAPPER.s          ; For handling traps 
ALIGN
INCLUDE    ../Bibliotecas/System/E_CALL_HANDLER.s   ; For handling sys calls 
ALIGN
INCLUDE    ../Bibliotecas/System/EXT_I_HANDLER.s    ; For handling external interrupts
ALIGN
INCLUDE    ../Bibliotecas/System/LCD.s              ; For handling LCD operations
ALIGN
INCLUDE    ../Bibliotecas/System/TIMER.s            ; For interfacing with the timer
ALIGN
INCLUDE    ../Bibliotecas/System/BUTTONS.s          ; For interfacing with the buttons
ALIGN
INCLUDE    ../Bibliotecas/System/KEYPAD.s           ; For interfacing with the keypad
ALIGN
INCLUDE    ../Bibliotecas/System/BUZZER.s           ; For interfacing with the buzzer
ALIGN
INCLUDE    ../Bibliotecas/System/UTIL.s             ; Assorted useful functions
ALIGN
INCLUDE    ../Bibliotecas/System/LED.s              ; For writing to the LEDs
; ---------------------------------------

; User Space: -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ORG 0x0004_0000

; User Stack: ---------------------------
ALIGN
MAIN_STACK   DEFS 500
MAIN_STACK_TOP
; ---------------------------------------

; Main Program:

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
MAIN        
            ; Write user instructions to lcd
            LA      A0, INSTRUCTIONS             
            LI      A7, E_PRINT_STRING
            ECALL

            ; Set up keystream with system call, pass in user space pointers.
            LA      A0, KEY_STREAM              
            LA      A1, KEY_STREAM_F
            LI      A7, E_K_READ_KEY_STREAM    
            ECALL


MAIN_LOOP   
            ; Load keypress flag
            LA T0, KEY_STREAM_F
            LW S0, 0[T0]

            BLTZ    S0, MAIN_LOOP               ; If flag is still -1 (no change), do nothing (continue polling.)

            ; Flag set, key has been written, clear flag, then read key
            LI      S0, -1
            SW      S0, KEY_STREAM_F, T0        ; Clear flag

            LW      S0, KEY_STREAM              ; Read key
            
            LI      S1, TUNE_MAX                ; Tune out of range?
            BGTU    S0, S1, MAIN_LOOP

            LA      S1, TUNES                   ; Calculate address of tune and load into A0
            SLLI    S2, S0, 2                   ; Multiply offset by 4 to get word offset
            ADD     S1, S1, S2
            LW      A0, [S1]

            LI      A7, E_B_PLAY_TUNE           
            ECALL

            LI      A7, E_CLEAR                 ; Clear the display
            ECALL

            LA      A0, PREFIX                  ; Write "Tune: " to lCD
            LI      A7, E_PRINT_STRING
            ECALL

            MV      A0, S0
            ADDI    A0, A0, 48                  ; ASCII Offset
            LI      A7, E_PRINT_CHAR            ; Print tune number to LCD
            ECALL                   

            J   MAIN_LOOP


; -----------------------------------------------------------------------
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

; Defined Memory: -----------------------
KEY_STREAM           DEFW      0
KEY_STREAM_F         DEFW     -1        ; Sticky bit / flag that goes high when key stream has been written to by ISR
; ---------------------------------------

; User Library Imports ----------------
; ---------------------------------------
; Write user instructions to lcd
; Macros: -------------------------------
INTERRUPT_ADDR      EQU     0x0001_0400
INTERRUPT_EN_O      EQU     0x04
INTERRUPT_BTN_BIT   EQU     5
INTERRUPT_MODE_O    EQU     0x0C
; ---------------------------------------


TUNES ;
DEFW    TUNE_0
DEFW    TUNE_1
DEFW    TUNE_2

TUNE_MAX EQU 2

ALIGN
PREFIX                  DEFB "Tune: ",0
INSTRUCTIONS            DEFB "Press 0,1 or 2:",0


ALIGN ; God Save The King (At time of writing, though I hear he is pretty healthy)
TUNE_0	    DEFB	 C_LOW,     70
            DEFB	 REST,      10
            DEFB	 C_LOW,     80
            DEFB	 D_HIGH,    80
            DEFB	 B_LOW,     120
            DEFB	 C_LOW,     40
            DEFB	 D_HIGH,    80

            DEFB	 E_HIGH,    70
            DEFB	 REST,      10
            DEFB	 E_HIGH,    80
            DEFB	 F_HIGH,    80
            DEFB	 E_HIGH,    120
            DEFB	 D_HIGH,    40
            DEFB	 C_LOW,     80

            DEFB	 D_HIGH,    80
            DEFB	 C_LOW,     80
            DEFB	 B_LOW,     80
            DEFB	 C_LOW,     160

            DEFB	 EOF

ALIGN
TUNE_1 ; Seven Nation Army (The white stripes)
            DEFB    E_HIGH, 48
            DEFB    REST, 24
            DEFB    E_HIGH, 24
            DEFB    G_HIGH, 36
            DEFB    E_HIGH, 36
            DEFB    D_HIGH, 24

            DEFB    C_LOW, 96
            DEFB    B_LOW, 96

            DEFB    E_HIGH, 72
            DEFB    E_HIGH, 24
            DEFB    G_HIGH, 36
            DEFB    E_HIGH, 36
            DEFB    D_HIGH, 24

            DEFB    C_LOW, 96
            DEFB    B_LOW, 96



            DEFB    E_HIGH, 48
            DEFB    REST, 24
            DEFB    E_HIGH, 24
            DEFB    G_HIGH, 36
            DEFB    E_HIGH, 36
            DEFB    D_HIGH, 24

            DEFB    C_LOW, 96
            DEFB    B_LOW, 96

            DEFB    E_HIGH, 72
            DEFB    E_HIGH, 24
            DEFB    G_HIGH, 36
            DEFB    E_HIGH, 36
            DEFB    D_HIGH, 24

            DEFB    C_LOW, 96
            DEFB    B_LOW, 24
            DEFB    E_HIGH, 24
            DEFB    E_HIGH, 24
            DEFB    E_HIGH, 24



            DEFB    G_HIGH, 24
            DEFB    E_HIGH, 24
            DEFB    E_HIGH, 48
            DEFB    REST, 96

            DEFB    REST, 72
            DEFB    D_HIGH, 24
            DEFB    E_HIGH, 24
            DEFB    D_HIGH, 24
            DEFB    E_HIGH, 24
            DEFB    D_HIGH, 24

            DEFB    E_HIGH, 24
            DEFB    D_HIGH, 24
            DEFB    E_HIGH, 24
            DEFB    D_HIGH, 24
            DEFB    E_HIGH, 36
            DEFB    E_HIGH, 36
            DEFB    E_HIGH, 24

            DEFB    E_HIGH, 48
            DEFB    REST, 48
            DEFB    REST, 24
            DEFB    E_HIGH, 24
            DEFB    E_HIGH, 24
            DEFB    E_HIGH, 24



            DEFB    EOF


ALIGN
TUNE_2 ; Nokia ringtone (Francisco Tárrega's Gran Vals)

        DEFB    E_HIGH,        10
        DEFB    D_HIGH,        10
        DEFB    FSHARP_LOW,   20
        DEFB    GSHARP_LOW,   20

        DEFB    CSHARP_HIGH,   10
        DEFB    B_LOW,        10
        DEFB    D_LOW,        20
        DEFB    E_LOW,        20

        DEFB    B_LOW,        10
        DEFB    A_LOW,        10
        DEFB    CSHARP_LOW,   20
        DEFB    E_LOW,        20
        DEFB    A_LOW,        40

        DEFB    EOF
