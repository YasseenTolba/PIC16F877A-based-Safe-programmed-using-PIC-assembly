#include <xc.inc> 
    
; * CONFIG
    CONFIG  FOSC = HS             ; Oscillator Selection bits (HS oscillator)
    CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled)
    CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
    CONFIG  BOREN = OFF           ; Brown-out Reset Enable bit (BOR disabled)
    CONFIG  LVP = OFF             ; Low-Voltage (Single-Supply) In-Circuit Serial Programming Enable bit (RB3 is digital I/O, HV on MCLR must be used for programming)
    CONFIG  CPD = OFF             ; Data EEPROM Memory Code Protection bit (Data EEPROM code protection off)
    CONFIG  WRT = OFF             ; Flash Program Memory Write Enable bits (Write protection off; all program memory may be written to by EECON control)
    CONFIG  CP = OFF              ; Flash Program Memory Code Protection bit (Code protection off)  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; * equ aka #define to be placed here  
; Vars  
wrong_entry_c       EQU 0x70 
delay_count_1       EQU 0X71
delay_count_2       EQU 0X72
delay_count_3       EQU 0X73
enter_state         EQU 0X74
gen_counter         EQU 0X75
user_pass           EQU 0X76
pass_state          EQU 0X77
master_pass         EQU 0X78
safe_flags          EQU 0X79
int_close_safe      EQU 0X7A
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LEDs
white_LED       EQU	5	; White LED always on
selenoid        EQU	4	; selonoid
green_LED	    EQU 3	; Green
red_LED_0	    EQU 0	; Red LED 0
red_LED_1	    EQU 1	; Red LED 1
red_LED_2	    EQU 2	; Red LED 2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
buzzer	        EQU 6	; Buzzer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PINs
pin_1            EQU 4	; PIN 1
pin_2            EQU 5	; PIN 2
pin_3            EQU 6	; PIN 3
pin_4            EQU 7	; PIN 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; buttons
enter_pb         EQU 3	; Enter button
close_pb         EQU 0	; Close safe button
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 7 segment display
sev_seg_0      EQU 0 ; 7 segment display 0
sev_seg_1      EQU 1 ; 7 segment display 1
sev_seg_2      EQU 2 ; 7 segment display 2
sev_seg_3      EQU 3 ; 7 segment display 3
; * end of equ
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; * Interrupt vector
psect   RESET_VECT,class=CODE,delta=2 ; PIC10/12/16
RESET_VECT:
    GOTO        setup 
psect   INT_VECT,class=CODE,delta=2 ; PIC10/12/16
INT_VECT:   
    BTFSC       INTCON, 1    ; RPB 0 interrupt flag, when pushed at falling edge then excute
    call        int_ISR      ; excute this once flag is raised 
    RETFIE                   ; return from interrupt
; * end of interrupt vector
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; * Interrupt service Routine
int_ISR:
    lock_safe:
        BTFSS       PORTC, selenoid     ; check pin staus if safe unlocked then skip jmp and close safe
        GOTO        end_int_ISR         ; else safe is locked so jmp to main
        BCF		    PORTC, selenoid     ; turn off selonoid
        BSF         int_close_safe, 0
        CALL        sev_seg_disp_C
    end_int_ISR:
    BCF         INTCON, 1              ; ! clear interrupt flag
    return
; * End of ISR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; * Setup
setup:
    CALL        PORTS_init
    CALL        Interrupt_init
    BANKSEL     PORTC           ; to ensure that the bank is set to PORTC
; * end of setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; * Main program
main:
    BTFSC       safe_flags, 0
    CALL        safe_locked_inf

    BTFSC       int_close_safe, 0   
    CALL        EEPROM_write_set_flag_zero

    BTFSC       int_close_safe, 0   ; if safe is closed using interrupt then sleep
    SLEEP

    CALL	    delay_100_ms
    CALL	    delay_100_ms
    CALL	    delay_100_ms
    
    BTFSS	    PORTB, enter_pb	    ; Input password
    GOTO	    check_new_pass      ; if pin is zero aka button pressed then jmp 
    GOTO	    main                ; else jmp to main

    check_new_pass:
    BTFSC       PORTC, selenoid     ; check if safe is unlocked
    GOTO        set_new_pass        ; set new password
    CALL	    enter_button        ; if safe is closed check for entered password
    GOTO	    main               

; * end of main program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; * Sub-routines
enter_button:

    MOVF        master_pass, 0         ; move master_pass to w
    MOVWF       pass_state             ; move w to pass_state
    MOVF        PORTB, 0               ; move portb to w to check password condition
    XORWF       pass_state, 1          ; xor w with pass_state and save result in pass_state

    BTFSC	    pass_state, 4	    
    GOTO	    user_password

    BTFSC	    pass_state, 5	    
    GOTO	    user_password

    BTFSC	    pass_state, 6	    
    GOTO	    user_password

    BTFSC	    pass_state, 7	    
    GOTO	    user_password

    GOTO        safe_open

    user_password:

    MOVF        user_pass, 0           ; move user_pass to w
    MOVWF       pass_state             ; move w to pass_state
    MOVF        PORTB, 0               ; move portb to w to check password condition
    XORWF       pass_state, 1          ; xor w with pass_state and save result in pass_state

    BTFSC	    pass_state, 4	    
    GOTO	    safe_close

    BTFSC	    pass_state, 5	    
    GOTO	    safe_close

    BTFSC	    pass_state, 6	    
    GOTO	    safe_close

    BTFSC	    pass_state, 7	    
    GOTO	    safe_close

    safe_open:

    BSF		    PORTC, selenoid	        ; open safe 
    MOVLW       0b00000001              ; used for red leds, wrong entry
    MOVWF       wrong_entry_c
    BCF         PORTC, red_LED_0	    ; red led 0 off
    BCF         PORTC, red_LED_1	    ; red led 1 off
    BCF         PORTC, red_LED_2	    ; red led 2 off
    BSF         PORTC, white_LED        ; white led on
    CALL        sev_seg_disp_O          ; display O on 7 segment display
    
    CALL        EEPROM_write_set_flag_zero

    RETURN

    safe_close:
    BCF		    PORTC, selenoid         ;keep safe closed
    CALL        sev_seg_disp_C          ; display C on 7 segment display
    
    BTFSC       wrong_entry_c, 0        ; skip if zero
    GOTO        wrong_0

    BTFSC       wrong_entry_c, 1        ; skip if zero
    GOTO        wrong_1

    BTFSC       wrong_entry_c, 2        ; skip if zero
    GOTO        wrong_2

    Return      

    wrong_0:
    BSF		    PORTC, red_LED_0        ; turn on red led 0
    CALL        sev_seg_disp_1          ; display 1 on 7 segment display
    RLF         wrong_entry_c, 1        ; rotate left through carry
    Return        

    wrong_1:
    BSF		    PORTC, red_LED_1        ; turn on red led 1
    CALL        sev_seg_disp_2          ; display 2 on 7 segment display
    RLF         wrong_entry_c, 1        ; rotate left through carry
    Return      

    wrong_2:
    BSF		    PORTC, red_LED_2        ; turn on red led 2
    BCF         PORTC, white_LED      ; turn off white led
    CALL        sev_seg_disp_E          ; display E on 7 segment display
    CLRF        gen_counter             ; clear buzzer counter
    MOVLW       3                       ; move three into WREG as loop counter
    MOVWF       gen_counter

        CALL        EEPROM_write_set_flag_one

        loop3:                           
        BSF         PORTC, buzzer        ; turn on buzzer
        CALL	    delay_1_sec
        BCF         PORTC, buzzer        ; turn off buzzer
        CALL        delay_1_sec
        DECFSZ      gen_counter, 1
        GOTO        loop3

        GOTO        safe_locked_inf

    safe_locked_inf:

        BSF         PORTC, red_LED_0        ; turn on red led 0
        BSF         PORTC, red_LED_1        ; turn on red led 1
        BSF         PORTC, red_LED_2        ; turn on red led 2
        BCF         PORTC, white_LED        ; turn off white led
        CALL        sev_seg_disp_E          ; display E on 7 segment display

        BTFSS	    PORTB, enter_pb	        ; Input password
        GOTO	    master_pass_locked      ; if pin is zero aka button pressed then jmp 
        GOTO	    safe_locked_inf                     ; else jmp to main

        master_pass_locked:
            MOVF        master_pass, 0         ; move master_pass to w
            MOVWF       pass_state             ; move w to pass_state
            MOVF        PORTB, 0               ; move portb to w to check password condition
            XORWF       pass_state, 1          ; xor w with pass_state and save result in pass_state

            BTFSC	    pass_state, 4	    
            GOTO	    safe_locked_inf

            BTFSC	    pass_state, 5	    
            GOTO	    safe_locked_inf

            BTFSC	    pass_state, 6	    
            GOTO	    safe_locked_inf

            BTFSC	    pass_state, 7	    
            GOTO	    safe_locked_inf

            GOTO        safe_open

sev_seg_disp_C:
    BCF         PORTD, sev_seg_0    ; 7 segment display 0
    BCF         PORTD, sev_seg_1    ; 7 segment display 1
    BSF         PORTD, sev_seg_2    ; 7 segment display 2
    BSF         PORTD, sev_seg_3    ; 7 segment display 3
    return

sev_seg_disp_O:
    BCF         PORTD, sev_seg_0    ; 7 segment display 0
    BCF         PORTD, sev_seg_1    ; 7 segment display 1
    BCF         PORTD, sev_seg_2    ; 7 segment display 2
    BCF         PORTD, sev_seg_3    ; 7 segment display 3
    return

sev_seg_disp_E:
    BCF         PORTD, sev_seg_0    ; 7 segment display 0
    BSF         PORTD, sev_seg_1    ; 7 segment display 1
    BSF         PORTD, sev_seg_2    ; 7 segment display 2
    BSF         PORTD, sev_seg_3    ; 7 segment display 3
    return

sev_seg_disp_1:
    BSF         PORTD, sev_seg_0    ; 7 segment display 0
    BCF         PORTD, sev_seg_1    ; 7 segment display 1
    BCF         PORTD, sev_seg_2    ; 7 segment display 2
    BCF         PORTD, sev_seg_3    ; 7 segment display 3
    return

sev_seg_disp_2:
    BCF         PORTD, sev_seg_0    ; 7 segment display 0
    BSF         PORTD, sev_seg_1    ; 7 segment display 1
    BCF         PORTD, sev_seg_2    ; 7 segment display 2
    BCF         PORTD, sev_seg_3    ; 7 segment display 3
    return

sev_seg_disp_F:
    BSF         PORTD, sev_seg_0    ; 7 segment display 0
    BSF         PORTD, sev_seg_1    ; 7 segment display 1
    BSF         PORTD, sev_seg_2    ; 7 segment display 2
    BSF         PORTD, sev_seg_3    ; 7 segment display 3
    return

set_new_pass:

    ; check if both passwords are the same
    MOVF        user_pass, 0            ; move user_pass to w
    MOVWF       pass_state              ; move w to pass_state
    MOVF        PORTB, 0                ; move portb to w to check password condition
    XORWF       pass_state, 1           ; xor w with pass_state and save result in pass_state

    BTFSC	    pass_state, 4	    
    GOTO        exc_new_pass

    BTFSC	    pass_state, 5	    
    GOTO        exc_new_pass

    BTFSC	    pass_state, 6	    
    GOTO        exc_new_pass

    BTFSC	    pass_state, 7	    
    GOTO        exc_new_pass

    ; in case both passwords are the same
    CALL        sev_seg_disp_E         ; display O on 7 segment display
    BSF         PORTC, red_LED_0        ; turn on red led
    BSF         PORTC, red_LED_1        ; turn on red led
    BSF         PORTC, red_LED_2        ; turn on red led
    CALL        delay_1_sec            ; delay 1 sec
    BCF         PORTC, red_LED_0        ; turn off red led
    BCF         PORTC, red_LED_1        ; turn off red led
    BCF         PORTC, red_LED_2        ; turn off red led
    CALL        delay_1_sec            ; delay 1 sec
    CALL        sev_seg_disp_O          ; display O on 7 segment display
    GOTO        main

    exc_new_pass:
    ; move values of PORTB, aka new password to user_pass
    MOVF        PORTB, 0               ; move portb to w to check password condition
    MOVWF       user_pass              ; set new password
    CALL        sev_seg_disp_F         ; display F on 7 segment display
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; * Write data to EEPROM
    BANKSEL	    EECON1
    BTFSC       EECON1, 1         ;Wait for write
    GOTO        $-1               ;to complete
    BANKSEL	    EEADR		; bank 2
    MOVF        0xFF,W             ;Data Memory       ; address in EEPROM
    MOVWF       EEADR             ;address to write
    MOVF        user_pass,W       ;Data Memory Value ; user password
    MOVWF       EEDATA            ;to write
    BANKSEL	    EECON1
    BCF         EECON1,7      ;Point to DATA memory
    BSF         EECON1,2       ;Enable writes

    BCF         INTCON,7        ;Disable INTs

    MOVLW       0x55
    MOVWF       EECON2            ;Write 55h
    MOVLW       0xAA
    MOVWF       EECON2            ;Write AAh
    BSF         EECON1,1         ;Set WR bit to begin write

    BSF         INTCON,7        ;Enable INTs.
    BCF         EECON1,2       ;Disable writes
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    BANKSEL	PORTC
    BCF         PORTC, white_LED       ; turn off white led
    BSF         PORTC, red_LED_0       ; turn on red led 0
    CALL        delay_1_sec            ; delay 1 second
    BSF         PORTC, white_LED       ; turn on white led
    BSF         PORTC, red_LED_1       ; turn on red led 1
    CALL        delay_1_sec            ; delay 1 second
    BCF         PORTC, white_LED       ; turn off white led
    BSF         PORTC, red_LED_2       ; turn on red led 2
    CALL        delay_1_sec            ; delay 1 second
    BSF         PORTC, white_LED       ; turn on white led
    BCF         PORTC, red_LED_0       ; turn off RED LED 0
    BCF         PORTC, red_LED_1       ; turn off RED LED 1
    BCF         PORTC, red_LED_2       ; turn off RED LED 2
    CALL        sev_seg_disp_O         ; display O on 7 segment display

    ;CALL        EEPROM_write_set_flag_zero ; open safe
    GOTO        main

delay_100_ms:

    MOVLW       117
    MOVWF       delay_count_1
    MOVLW       8
    MOVWF       delay_count_2
    MOVLW       3
    MOVWF       delay_count_3

    loop_1:

    DECFSZ      delay_count_1, 1
    GOTO        loop_1
    DECFSZ      delay_count_2, 1
    GOTO        loop_1
    DECFSZ      delay_count_3, 1
    GOTO        loop_1
    NOP
    NOP
    RETURN

delay_1_sec:

    MOVLW       189
    MOVWF       delay_count_1
    MOVLW       75
    MOVWF       delay_count_2
    MOVLW       21
    MOVWF       delay_count_3

    loop_2:

    DECFSZ      delay_count_1, 1
    GOTO        loop_2
    DECFSZ      delay_count_2, 1
    GOTO        loop_2
    DECFSZ      delay_count_3, 1
    GOTO        loop_2
    RETURN

EEPROM_write_set_flag_zero:
    BCF         safe_flags, 0        ; set safe_flags bit 0 to 1
        ; write to EEPROM the flag state
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; * Write data to EEPROM
        BANKSEL	    EECON1
        BTFSC       EECON1, 1         ;Wait for write
        GOTO        $-1               ;to complete
        BANKSEL	    EEADR		; bank 2
        MOVF        0xFA,W             ;Data Memory       ; address in EEPROM
        MOVWF       EEADR             ;address to write
        MOVF        safe_flags,W       ;Data Memory Value ; user password
        MOVWF       EEDATA            ;to write
        BANKSEL	    EECON1
        BCF         EECON1,7      ;Point to DATA memory
        BSF         EECON1,2       ;Enable writes

        BCF         INTCON,7        ;Disable INTs.

        MOVLW       0x55
        MOVWF       EECON2            ;Write 55h
        MOVLW       0xAA
        MOVWF       EECON2            ;Write AAh
        BSF         EECON1,1         ;Set WR bit to begin write

        BSF         INTCON,7        ;Enable INTs.
        BCF         EECON1,2       ;Disable writes
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        BANKSEL     PORTC
        RETURN

    EEPROM_write_set_flag_one:
        BSF         safe_flags, 0        ; set safe_flags bit 0 to 1
        ; write to EEPROM the flag state
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; * Write data to EEPROM
        BANKSEL	    EECON1
        BTFSC       EECON1, 1         ;Wait for write
        GOTO        $-1               ;to complete
        BANKSEL	    EEADR		; bank 2
        MOVF        0xFA,W             ;Data Memory       ; address in EEPROM
        MOVWF       EEADR             ;address to write
        MOVF        safe_flags,W       ;Data Memory Value ; user password
        MOVWF       EEDATA            ;to write
        BANKSEL	    EECON1
        BCF         EECON1,7      ;Point to DATA memory
        BSF         EECON1,2       ;Enable writes

        BCF         INTCON,7        ;Disable INTs.

        MOVLW       0x55
        MOVWF       EECON2            ;Write 55h
        MOVLW       0xAA
        MOVWF       EECON2            ;Write AAh
        BSF         EECON1,1         ;Set WR bit to begin write

        BSF         INTCON,7        ;Enable INTs.
        BCF         EECON1,2       ;Disable writes
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        BANKSEL     PORTC
        RETURN

; * end of sub-routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; * Init functions
PORTS_init:
    ; Setting up ports
    BANKSEL	    TRISB
    MOVLW	    0b00000000          ; setting all port C as output
    MOVWF	    TRISC	            ; setting all port C as output
    MOVLW	    0b11111111          ; setting all port B as input
    MOVWF	    TRISB               ; setting all port B as input
    MOVLW	    0b00000000          ; setting all port D as output
    MOVWF	    TRISD	            ; setting all port D as output
    BCF	        OPTION_REG, 7       ; enable pull up resistors for PORTB

    BANKSEL	    PORTC
    ; Decleration for init values
    BSF	        PORTC, white_LED	; White LED always on
    BCF	        PORTC, selenoid	    ; selenoid
    BCF	        PORTC, red_LED_0	; Red LED 0
    BCF	        PORTC, red_LED_1	; Red LED 1
    BCF	        PORTC, red_LED_2	; Red LED 2

    BCF	        PORTC, buzzer	    ; Buzzer
    BCF	        PORTC, 7	        ; not used

    ; Defult values for 7 seg to display C for closed
    BCF         PORTD, sev_seg_0    ; 7 segment display 0
    BCF         PORTD, sev_seg_1    ; 7 segment display 1
    BSF         PORTD, sev_seg_2    ; 7 segment display 2
    BSF         PORTD, sev_seg_3    ; 7 segment display 3

    BCF         PORTD, 4            ; not used
    BCF         PORTD, 5            ; not used
    BCF         PORTD, 6            ; not used
    BCF         PORTD, 7            ; not used

    MOVLW       0b00000001          ; used for red leds, wrong entry
    MOVWF       wrong_entry_c

    MOVLW       0b10100000              ; predefined password
    MOVWF       user_pass                ; store in user_pass

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; * Read data from EEPROM
BANKSEL	    EEADR
MOVF        0xFF,W               ; Data Memory
MOVWF       EEADR               ; address to read
BANKSEL	    EECON1  
BCF         EECON1,7        ; Point to Data memory
BSF         EECON1,0           ; EE Read
BANKSEL	    EEDATA
MOVF        EEDATA,W            ; W = EEDATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVWF       user_pass           ; store in user_pass
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; * Read data from EEPROM
BANKSEL	    EEADR
MOVF        0xFA,W               ; Data Memory
MOVWF       EEADR               ; address to read
BANKSEL	    EECON1  
BCF         EECON1,7        ; Point to Data memory
BSF         EECON1,0           ; EE Read
BANKSEL	    EEDATA
MOVF        EEDATA,W            ; W = EEDATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVWF       safe_flags           ; store in user_pass

    MOVLW       0b00000000              ; password state
    MOVWF       pass_state              ; store in pass_state

    MOVLW       0b10100000              ; master password
    MOVWF       master_pass             ; store in master_pass

    MOVLW       0b00000000              ; interrupt close safe
    MOVWF       int_close_safe          ; store in int_close_safe

    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Interrupt_init:
    BANKSEL        OPTION_REG
    BCF            OPTION_REG, 6   ; select falling edge interrupt --> INTEDG = 0
    BCF            INTCON, 1       ; clears flag bit   --> INTF = 0
    BSF            INTCON, 7       ; enables interrupt --> GIE = 1
    BSF            INTCON, 4       ; enables interrupt --> INTE = 1
    return
; * end of init functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
END RESET_VECT