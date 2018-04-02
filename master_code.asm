#include <p16f690.inc> ; PIC Number
  
  CBLOCK   0x20          ; Define Memory Bytes
  Byte
  Matlab_Command
  ENDC
  #define ss_sensors PORTC,2 ; Slave Select sensors (RC2)
  #define ss_motor PORTC,3 ; Slave Select stepper motor (RC3)

  
BANK0    MACRO
  BCF      STATUS,RP0
  BCF      STATUS,RP1
  ENDM
BANK1    MACRO
  BSF      STATUS,RP0
  BCF      STATUS,RP1
  ENDM
BANK2    MACRO
  BCF      STATUS,RP0
  BSF      STATUS,RP1
  ENDM
BANK3    MACRO
  BSF      STATUS,RP0
  BSF      STATUS,RP1
  ENDM
  
 __CONFIG (_INTRC_OSC_NOCLKOUT & _FOSC_INTRCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOR_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF) 
 
  ORG      0x00                   ; Start Programing
  CALL     INITIALIZATION
  GOTO     Main
  
  ORG      04h                   ; Start Interrupt Service Routine - ISR
  RETFIE                         ; Finish Interrupt Service Routine - ISR
  
;*************************************************************************;
Main                             ; Main Loop
   banksel	RCSTA
   bsf		RCSTA,CREN         ; Enable Receiver
   btfss	PIR1,RCIF          ; Wait Until Byte had been Received from MATLAB
   goto		$-1
   movfw	RCREG; If Needed Check WREG For Receiving
   movwf	Matlab_Command
   ;;;;	    BOF TESTING
   call		Send_Matlab
   goto		Main
   ;;;;	    EOF TESTING
   BANK0
   decfsz	Matlab_Command
     goto $+2		
   goto		Com_S_1
   decfsz	Matlab_Command
     goto	Main
   goto		Com_S_2
   
Com_S_1
   BANK0
   bcf		ss_sensors
   movlw	d'1'
   banksel	SSPBUF
   movwf	SSPBUF
   banksel	SSPSTAT
   btfss	SSPSTAT,BF  ; check if transmitted
     goto $-1
   banksel	SSPBUF 
   movfw	SSPBUF ; read the received byte 
   BANK0
   bsf		ss_sensors
   call		Send_Matlab	    
 goto Main
   
Com_S_2
   BANK0
   bcf		ss_motor
   movlw	d'2'
   banksel	SSPBUF
   movwf	SSPBUF
   banksel	SSPSTAT
   btfss	SSPSTAT,BF  ; check if transmitted
   goto $-1
   banksel	SSPBUF 
   movfw	SSPBUF ; read the received byte    
   bsf		ss_motor
   call		Send_Matlab
 goto Main
 ;************************************************************************;
DELAY
  MOVLW     d'20'                ; 20 us Delay
  MOVWF     Byte
  DECFSZ    Byte
  GOTO      $-1
  NOP
  RETURN  
 
 ;*******************************************************************;
Send_Matlab
    banksel	RCSTA
    BSF		RCSTA,SPEN       ; Data Direction Control
    ; Check Status of Transmit Bit, Wait Until Set   
    BANKSEL	TXSTA
    BTFSS	TXSTA, TRMT       
    GOTO $-1

    ; Load Working Register Into TXREG   
    BANKSEL     TXREG
    MOVWF	TXREG
    
    ;Done!
    RETURN
  
 ;************************************************************************;
INITIALIZATION
 
  BANK1
  ; Set Internal Oscillator Frequency to 8 MHz
  MOVLW      b'01110000'           
  MOVWF      OSCCON
  ; Setup RX/TX Communication 
    bcf        TXSTA,SYNC		    ; TXSTA,SYNC
    bsf        TXSTA,TXEN
    bsf        TXSTA,BRGH		    ; 19.2k at 8 MHz
    bcf        BAUDCTL,BRG16         
    movlw      0x19		    ; 19.2k at 8 MHz
    MOVWF      SPBRG  
    BSF        TXSTA,TRMT
  ; ADC Segment Initialization

  BANK2 
    clrf      ANSEL		    ; ALL DIGITAL Communication
    clrf      ANSELH		    ; ALL DIGITAL Communication
  
  BANK0
    bsf       RCSTA,SPEN
    clrf      PORTC

    
;    SPI below here
  banksel   TRISB
    bsf	    TRISB,4		    ; SDI is input
    bcf	    TRISC,7		    ; SDO is output
    bcf	    TRISB,6		    ; SCK is output
    bcf	    TRISC,3		    ; Output for Slave Select 1
    bcf	    TRISC,2		    ; Output for Slave Select 2

  banksel   PORTC
    bsf	    ss_motor		    ; Set High To Disable Communication (Left Slave PIC)
    bsf	    ss_sensors		    ; Set High To Disable Communication (Right Slave PIC)

  banksel   SSPSTAT
    movlw   b'01000000' ; SPI, middle of
    movwf   SSPSTAT ; output time sampling
  
  banksel   SSPCON ; BANK 0
    movlw   b'00110001' ; Mode 1,1 SPI Master Mode, 1/16 Fosc 
    movwf   SSPCON ; SSP is on
  return
    
END
