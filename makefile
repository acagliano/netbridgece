# Copyright (C) 2015-2020
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

include ../common.mk

LIB_SRC			:= bridgelib.asm
LIB_LIB			:= bridgelib.lib
LIB_8XV			:= bridgelib.8xv
LIB_H			:= bridgelib.h
LIB_EXAMPLES	:= $(shell ls -d examples/*)

all: $(LIB_8XV)

$(LIB_8XV): $(LIB_SRC)
	sed -i '' 's/BB.*_/\.lbl_/g' $(LIB_SRC)
	$(Q)$(FASMG) $< $@

clean:
	$(Q)$(call REMOVE,$(LIB_LIB) $(LIB_8XV))

install: all
	$(Q)$(call MKDIR,$(INSTALL_LIB))
	$(Q)$(call MKDIR,$(INSTALL_H))
	$(Q)$(call COPY,$(LIB_LIB),$(INSTALL_LIB))
	$(Q)$(call COPY,$(LIB_H),$(INSTALL_H))

examples: $(LIB_EXAMPLES)
$(LIB_EXAMPLES):
	$(MAKE) clean -C $@
	$(MAKE) -C $@

archive: bridgelib.zip
bridgelib.zip:
	zip bridgelib.zip README.md bridgelib.8xv bridgelib.lib bridgelib.h bridgelib.asm


.PHONY: all clean install examples archive $(LIB_EXAMPLES)
