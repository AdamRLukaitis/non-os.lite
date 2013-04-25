###
 # (C) Copyright 2013 Faraday Technology
 # BingYao Luo <bjluo@faraday-tech.com>
 #
 # This program is free software; you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation; either version 2 of the License, or
 # (at your option) any later version.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with this program; if not, write to the Free Software
 # Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 ##

export TOP_DIR ?= $(shell pwd)

include config.mk

LDFLAGS += -Ttext 0x00000000

# Move data section to memory, text section
# remain at flash
ifeq ($(IMAGE), RAM)
LDSFILE := ram.lds
else #ROM
ifeq ($(COPYSECT), data)
LDSFILE := rom.lds
else
LDSFILE := ram.lds
endif
endif

ELFNAME := bin/$(IMAGE)-nonos-$(COPYSECT)-$(PLATFORM)


dirs-y := lib board drivers app
objs-y := app/app.a lib/libUtils.a drivers/drivers.a board/board.a

.PHONY: all
all: print config $(dirs-y) $(ELFNAME).elf

.PHONY: print
print:
	@echo "Build directory: $(dirs-y)"
	@echo "Dependancy objects: $(objs-y)"

config: config.mk
	@echo "Configuration changes, make clean ... "
	@make clean
	@cd include && ln -sf platform_$(PLATFORM).h platform.h
	@touch config

.PHONY: $(dirs-y)
$(dirs-y):
	@make -C $@ all

$(ELFNAME).elf: start.o $(objs-y)
	$(LD) -Bstatic \
		-T $(LDSFILE) \
		$(LDFLAGS) \
		-nostartfiles \
		-nostdlib \
		start.o \
		--start-group \
		$(objs-y) -lgcc -lc -lm \
		--end-group \
		-L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) \
		-L $(shell dirname `$(CC) $(CFLAGS) -print-file-name=libc.a`) \
		-Map $(ELFNAME).map -o $(ELFNAME).elf
	$(OBJCOPY) -O binary  $(ELFNAME).elf $(ELFNAME).bin
	$(OD) -D  $(ELFNAME).elf > $(ELFNAME).dump

.PHONY:clean
clean:
	@find ./ -name '*.[oa]' | xargs rm -rf

.PHONY : distclean
distclean:
	find . -name "Makefile.depend" | xargs rm -f
	find . -name "*.o" -o -name "*.a" -o -name ".*.swp" -o -name "*.map" -o -name "*.elf" \
	-o -name "*.bin" -o -name "*.dump" | xargs rm -f
