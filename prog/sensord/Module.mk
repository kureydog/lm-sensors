#  Module.mk - Makefile for a Linux module for reading sensor data.
#  Copyright (c) 1998, 1999  Frodo Looijaard <frodol@dds.nl>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

# Note that MODULE_DIR (the directory in which this file resides) is a
# 'simply expanded variable'. That means that its value is substituted
# verbatim in the rules, until it is redefined. 
MODULE_DIR := prog/sensord
PROGSENSORDDIR := $(MODULE_DIR)

PROGSENSORDMAN1DIR := $(MANDIR)/man8
PROGSENSORDMAN1FILES := $(MODULE_DIR)/sensord.8

# Regrettably, even 'simply expanded variables' will not put their currently
# defined value verbatim into the command-list of rules...
PROGSENSORDTARGETS := $(MODULE_DIR)/sensord
PROGSENSORDSOURCES := $(MODULE_DIR)/sensord.c $(MODULE_DIR)/chips.c

# Include all dependency files. We use '.rd' to indicate this will create
# executables.
INCLUDEFILES += $(PROGSENSORDSOURCES:.c=.rd)

$(PROGSENSORDTARGETS): $(PROGSENSORDSOURCES:.c=.ro) lib/$(LIBSHBASENAME)
	$(CC) -o $@ $(PROGSENSORDSOURCES:.c=.ro) -Llib -lsensors

all-prog-sensord: $(PROGSENSORDTARGETS)
all :: all-prog-sensord

install-prog-sensord: all-prog-sensord
	mkdir -p $(SBINDIR) $(PROGSENSORDMAN1DIR)
	$(INSTALL) -o root -g root -m 755 $(PROGSENSORDTARGETS) $(SBINDIR)
	$(INSTALL) -o $(MANOWN) -g $(MANGRP) -m 644 $(PROGSENSORDMAN1FILES) $(PROGSENSORDMAN1DIR)
# install :: install-prog-sensord

clean-prog-sensord:
	$(RM) $(PROGSENSORDDIR)/*.rd $(PROGSENSORDDIR)/*.ro 
	$(RM) $(PROGSENSORDTARGETS)
clean :: clean-prog-sensord
