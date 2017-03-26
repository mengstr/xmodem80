SHELL		=  /bin/bash
EMULATIONBAUD=  9600
ESPPORT		?= /dev/ttyUSB0

ESPTOOL		=  /opt/esptool/esptool.py
ASM			=  /usr/bin/z80asm
SERIAL		=  minicom -b -D $(ESPPORT) $(EMULATIONBAUD)
SED			=  /bin/sed

TARGET1		= XR
TARGET2		= XS
DRIVE		= J:

INTERACTIVE:=$(shell [ -t 0 ] && echo 1)

all: $(TARGET1).hex $(TARGET2).hex 

full: clean flash

$(TARGET1).hex: $(TARGET1).Z80
	@echo [Z80ASM] $<
	@$(ASM) $(FLAGSHEX) $< -l$(basename $<).lst -o tmp1.tmp
	@srec_cat tmp1.tmp -binary -offset 0x100 -o tmp2.tmp -intel
	@tail -n +2 tmp2.tmp > $@
	@sed -i '/:......000000000000000000000000000000000000000000000000000000000000000000..$$/d' $@

$(TARGET2).hex: $(TARGET2).Z80
	@echo [Z80ASM] $<
	@$(ASM) $(FLAGSHEX) $< -l$(basename $<).lst -o tmp1.tmp
	@srec_cat tmp1.tmp -binary -offset 0x100 -o tmp2.tmp -intel
	@tail -n +2 tmp2.tmp > $@
	@sed -i '/:......000000000000000000000000000000000000000000000000000000000000000000..$$/d' $@

prepare:
	@echo -n Reset..
	@$(ESPTOOL) --baud $(EMULATIONBAUD) --port $(ESPPORT) --chip esp8266 --no-stub --after soft_reset read_mac > /dev/null
	@sleep 0.5
	@echo -n Autobaud..
	@echo -n -e "\x0d" > $(ESPPORT)
	@sleep 0.25
	@echo -n -e "\x0d" > $(ESPPORT)
	@sleep 0.25
	@echo -n -e "\x0d" > $(ESPPORT)
	@sleep 0.25
	@echo -n -e "\x0d" > $(ESPPORT)
	@sleep 0.25
	@echo -n Boot..
	@echo "B" > $(ESPPORT)
	@sleep 0.25
	@echo -n CD..
	@echo $(DRIVE) > $(ESPPORT)
	@sleep 0.25


xfer:
	@echo -n ERA..
	@echo "ERA $(THEFILE)" > $(ESPPORT)
	@sleep 0.25
	@echo -n PIP..
	@echo "A:PIP $(DRIVE)$(THEFILE)=CON:" > $(ESPPORT)
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
		echo -n "$$line" > $(ESPPORT); \
		echo -n -e "\r\n" > $(ESPPORT); \
		sleep 0.01; \
	done
	@echo -n " "
else
	@echo -n UPLOAD..
	@cat $(THEFILE) | \
	$(SED) -e '/INCLUDE/s/\"//g' | \
	while IFS= read -r line;do \
		echo -e "$$line\r" > $(ESPPORT); \
		sleep 0.01; \
	done
endif
	@echo -e "\x1A" > $(ESPPORT)


flash: $(TARGET1).hex $(TARGET2).hex
	@echo -n "[UPLOAD $@] "
	@$(MAKE) --no-print-directory prepare
	@echo
	@$(MAKE) --no-print-directory xfer THEFILE=$(TARGET1).hex
	@sleep 2
	@$(MAKE) --no-print-directory xfer THEFILE=$(TARGET2).hex
	@sleep 2
	@echo HEX2COM...
	@echo "A:LOAD $(TARGET1)" > $(ESPPORT)
	@echo "A:LOAD $(TARGET2)" > $(ESPPORT)
	@$(SERIAL) 

clean:
	@echo "[clean]"
	@rm -rf *~ 
	@rm -rf *.{cap,log,tmp,rom,bin,hex,lst}
