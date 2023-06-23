# PIC16F877A-based-Safe-programmed-using-PIC-assembly
**Summary**

Assembly program for a PIC16F877A microcontroller that controls a safe. User inputs the password using dual inline package switches. Based on the user input the program either opens the safe for correct password or indicates an incorrect password is entered, then finally, on the third wrong entry an alarm is turned on and safe until master password is entered. The state of the safe is displayed on a seven-segment display. The user password is recorded in the EEPROM.

**Approach**

To set up the password for the first time the safe needs to be unlocked either by using the master password or the user password, then the user enters the new password and presses the enter password button. If the password is not the same as the old password, red LEDs will turn on in sequence and the seven segment display will display the letter ‘F’. To test the program the user will enter the password using the DIP switches, the password will be evaluated bit by bit, in case of a match, the solenoid will be actuated in turn turning off the blue LED and turning on the Green LED. Otherwise, the red LED will be turned on. If the password is inserted incorrectly three times in a row, the safe will lock by turning on all three red LEDs and turning off the white LED. The seven segment and red LEDs will display the number of wrong entries. On the third wrong entry the safe will lock until master password is entered, seven segment will display ‘E’ and all three red LEDs will be on while, buzzer buzzes three times.

**Circuit Schematic**

<img width="732" alt="image" src="https://github.com/YasseenTolba/PIC16F877A-based-Safe-programmed-using-PIC-assembly/assets/55665255/1b6bffa2-894f-4451-9d3d-86e84e7f2a79">


The PIC16F877A is connected to a 16 MHZ external oscillator. Port B is set as output with its resistors as pull up. Port B is used for password and buttons entry. LEDs are connected to ground using 220 ohm resistors and to Port C in the MCU along the buzzer. The relay (solenoid) is connected also to Port C with its output connected to the blue and green LEDs. The seven-segment display is connected internally to a binary coded decimal decoder and connected to Port D. Reset button is pulled up using an external resistor and power source and is connected to a push button that is connected to ground. 
