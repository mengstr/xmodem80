SHELL		=  /bin/bash
EMULATIONBAUD=  9600
ESPPORT		?= /dev/ttyUSB0

ESPTOOL		=  /opt/esptool/esptool.py
ASM			=  /usr/bin/z80asm
SERIAL		=  minicom -b -D $(ESPPORT) $(EMULATIONBAUD)
SED			=  /bin/sed

TARGET		= XR
SRCS		= $(wildcard *.Z80)
DRIVE		= J:

INTERACTIVE:=$(shell [ -t 0 ] && echo 1)

all: $(TARGET).hex 

full: clean flash

$(TARGET).hex: $(SRCS)
	@echo [Z80ASM] $<
	@$(ASM) $(FLAGSHEX) $(TARGET).Z80 -l$(TARGET).lst -o tmp1.tmp
	@srec_cat tmp1.tmp -binary -offset 0x100 -o tmp2.tmp -intel
	@tail -n +2 tmp2.tmp > $@
	@sed -i '/:......000000000000000000000000000000000000000000000000000000000000000000..$$/d' $@

prepare:
	@echo -n Reset..
	@$(ESPTOOL) --baud $(EMULATIONBAUD) --port $(ESPPORT) --chip esp8266 --no-stub --after soft_reset read_mac > /dev/null
	@sleep 0.5
	@echo -n Autobaud..
	@echo -n -e "\x0d" > /dev/ttyUSB0
	@sleep 0.25
	@echo -n -e "\x0d" > /dev/ttyUSB0
	@sleep 0.25
	@echo -n -e "\x0d" > /dev/ttyUSB0
	@sleep 0.25
	@echo -n -e "\x0d" > /dev/ttyUSB0
	@sleep 0.25
	@echo -n Boot..
	@echo "B" > /dev/ttyUSB0
	@sleep 0.25
	@echo -n CD..
	@echo $(DRIVE) > /dev/ttyUSB0
	@sleep 0.25


xfer:
	@echo -n ERA..
	@echo "ERA $(THEFILE)" > /dev/ttyUSB0
	@sleep 0.25
	@echo -n PIP..
	@echo "A:PIP $(DRIVE)$(THEFILE)=CON:" > /dev/ttyUSB0
	@sleep 0.25
ifdef INTERACTIVE
	@echo -n UPLOAD ---%
	@$(eval LINES=$(shell cat $(THEFILE) | wc -l))
	@cnt=0; \
	cat $(THEFILE) | \
	$(SED) -e '/INCLUDE/s/\"//g' | \
	while IFS= read -r line;do \
		cnt=$$(( cnt+100)); \
		printf "\b\b\b\b%3d%%" $$(( $$cnt/$(LINES) )); \
		echo -n "$$line" > /dev/ttyUSB0; \
		echo -n -e "\r\n" > /dev/ttyUSB0; \
		sleep 0.01; \
	done
	@echo -n " "
else
	@echo -n UPLOAD..
	@cat $(THEFILE) | \
	$(SED) -e '/INCLUDE/s/\"//g' | \
	while IFS= read -r line;do \
		echo -e "$$line\r" > /dev/ttyUSB0; \
		sleep 0.01; \
	done
endif
	@echo -e "\x1A" > /dev/ttyUSB0


flash: $(TARGET).hex
	@echo -n "[UPLOAD $(TARGET)] "
	@$(MAKE) --no-print-directory prepare
	@$(MAKE) --no-print-directory xfer THEFILE=$(TARGET).hex
	@echo HEX2COM...
	@sleep 2
	@echo "A:LOAD $(TARGET)" > /dev/ttyUSB0
	@$(SERIAL) 

upload: 
#	@echo -n "[UPLOAD SOURCES] "
#	@$(MAKE) --no-print-directory prepare
#	@echo ""
#	@echo -n "[SED80.Z80] "
#	@$(MAKE) --no-print-directory xfer THEFILE=SED80.Z80
#	@sleep 2
#	@echo ""
#	@echo -n "[FILE.Z80] "
#	@$(MAKE) --no-print-directory xfer THEFILE=FILE.Z80
#	@sleep 2
#	@echo ""
#	@echo -n "[UTILS.Z80] "
#	@$(MAKE) --no-print-directory xfer THEFILE=UTILS.Z80
#	@sleep 2
#	@echo ""
#	@$(SERIAL) -load cpm8266 -sercfg $(EMULATIONBAUD)

clean:
	@echo "[clean]"
	@rm -rf *~ 
	@rm -rf *.{cap,log,tmp,rom,bin,hex,lst}
