
#include <p16f690.inc>
; Slave Demo Receiving a byte  and sending it back
 __CONFIG  _CP_OFF & _WDT_OFF & _INTOSCIO & _PWRTE_ON & _MCLRE_OFF & _BOR_OFF

    CBLOCK 0x20
       Digit
        W_TEMP   ; not used
        STATUS_TEMP ; not used
   ENDC
#define SS PORTC,3 ; Slave Select (RC3)
   
org 0x0 
   
 ; initialize oscillator  
    bsf         STATUS, RP0     ; switch to Bank 1
    MOVLW       b'01110000'     ; Set internal oscillator frequency to 8 MHz
    MOVWF       OSCCON

   ;initialize ports
   banksel ANSEL
   clrf ANSEL
   
   banksel TRISB
   ; configure SPI ports
   bsf TRISB,4  ; SDI is input
   bcf TRISC,7  ; SDO is output
   bsf TRISB,6   ; SCK is input
   bsf TRISC,6   ; SS line is an input 
   
 

   ;disable analog function on SDO, SDI, SCK , SS line for SPI function
   banksel ANSELH
   clrf ANSELH
 
  ; set up SPI port
  
   banksel SSPSTAT
   movlw b'01000000' ; SPI, middle of
   movwf SSPSTAT ; output time sampling
   BANKSEL SSPCON ; BANK 0
   movlw B'00110100' ; Mode 1,1 SPI Slave Mode,
; Slave Select Required
   movwf SSPCON ; SSP is on

   
Main  
   banksel SSPSTAT
   btfss SSPSTAT,BF
   goto $-1 ;wait for transmission completion 
   banksel SSPBUF
   movfw SSPBUF  ; put the result in W
   movwf Digit
   
  ; Here you can put action based on received Digit
  ; In this example I am sending it back in the next transmission (echo)
  ; but you can send back ADC values
    movlw d'22'
   movwf SSPBUF ; move into buffer for next transmission
   goto Main 
   end
 
   


