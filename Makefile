# Satellite-install Makefile for installing Satellite
# Copyright (C) 2016  Billy Holmes <billy@gonoph.net>
# 
# This file is part of Satellite-install.
# 
# Satellite-install is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
# 
# Satellite-install is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along with
# Satellite-install.  If not, see <http://www.gnu.org/licenses/>.

.PHONY: help install pre-install-only install-only post-install-only clean

BETA?=

PRE_SCRIPT:=scripts/1-pre.sh
INSTALL_SCRIPT:=scripts/2-install.sh
POST_SCRIPT:=scripts/3-post.sh
CLEAN_SCRIPT:=scripts/0-clean.sh
HAMMER_CONF:=conf/cli_config.yml.sh
HAMMER_CONF_INSTALLED:=$(HOME)/.hammer/cli_config.yml
BLOCKDEV_CONF:=etc/mongod.service.d/blockdev.conf
BLOCKDEV_CONF_INSTALLED:=/etc/systemd/system/mongod.service.d/blockdev.conf
SUDOERS_D:=etc/sudoers.d/mongodb
SUDOERS_D_INSTALLED:=/etc/sudoers.d/mongodb
PULP_SOURCES:=alternative.conf
PULP_SOURCES_INSTALLED:=/etc/pulp/content/sources/conf.d/alternative.conf
PULP_PATCH:=pulp_rpm-plugins-catalogers-yum.patch

help:
	@echo "Usage: make (help | install | pre-install-only | install-only | post-install-only | clean"
	@echo "	help - this help"
	@echo "	install - install satellite performing the pre, install and post sections"
	@echo "	pre-install-only - only perform the pre-install section"
	@echo "	install-only - only perform the install section"
	@echo "	post-install-only - only perform the post-install section"
	@echo "	clean - attempt to clean the install and refresh for a re-install" 

.FORCE_pre-install:
	rm -f .done_pre-install
.FORCE_install:
	rm -f .done_install
.FORCE_post_install:
	rm -f .done_post-install
pre-install-only: .FORCE_pre-install pre-install
install-only: .FORCE_install install
post-install-only: .FORCE_post-install post-install

REAL_PATH_PULP_PATCH:=$(shell realpath $(PULP_PATCH))
$(PULP_SOURCES_INSTALLED): $(PULP_SOURCES) $(PULP_PATCH)
	cd / ; patch -p0 < $(REAL_PATH_PULP_PATCH)
	install $(PULP_SOURCES) $@

$(HAMMER_CONF_INSTALLED): $(HAMMER_CONF)
	install -d $(shell dirname $@)
	./$(HAMMER_CONF) > $@

$(SUDOERS_D_INSTALLED): $(SUDOERS_D)
	install -d $(shell dirname $@)
	install $< $@

$(BLOCKDEV_CONF_INSTALLED): $(BLOCKDEV_CONF)
	install -d $(shell dirname $@)
	install $< $@

pre-install: .done_pre-install
ifdef BETA
.done_pre-install: export BETA=1
endif
.done_pre-install: $(HAMMER_CONF_INSTALLED) $(BLOCKDEV_CONF_INSTALLED) $(SUDOERS_D_INSTALLED) $(PRE_SCRIPT)
	./$(PRE_SCRIPT)
	touch $@

install: pre-install .done_install post-install
ifdef BETA
.done_install: export BETA=1
endif
.done_install: $(INSTALL_SCRIPT) $(PULP_SOURCES_INSTALLED)
	./$(INSTALL_SCRIPT)
	touch $@

post-install: .done_post-install
ifdef BETA
.done_post-install: export BETA=1
endif
.done_post-install: $(POST_SCRIPT)
	./$(POST_SCRIPT)
	touch $@

.FORCE_clean:
clean: .FORCE_clean
	./$(CLEAN_SCRIPT)
