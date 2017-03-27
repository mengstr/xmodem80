# xmodem80 - Xmodem for Z80 CP/M 2.2 for CON:

### What

By some reason I couldn't get any of the existing xmodem programs to work
under my CP/M-8266 project so I decided to write my own small xmodem 
implementation.

I guess the main reasion for the problems is that I needed to use the
standard main console device CON: for I/O, most old implementations uses a 
separate device, either as PUN:/RDR: or with direct access to the UART hardware.

![Screenshot](/Pic/screenshot.png?raw=true "Screenshot of xr downloading its source")

### Assembly

The sources for xs and xr can be compiled by the SLR Z80ASM in the CP/M machine or 
cross-compiled with the "z80asm" package in Linux. I guess many other assemblers can 
be used as well with the source unmodified or slightly altered for that assemblers 
particular syntax, but those are the ones I use.

### Usage

Receiving a file on the CP/M machine is as easy as `XR FILENAME.EXT` or with a drive letter added as `XR B:FILENAME.EXT`

Sending a file from the CP/M is `XS FILENAME.EXT` or `XS B:FILENAME.EXT`

Pressing CTRL-X will exit the program while running.
