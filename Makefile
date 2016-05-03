.PHONY: help install pre-install-only install-only post-install-only clean

PRE_SCRIPT:=scripts/1-pre.sh
INSTALL_SCRIPT:=scripts/2-install.sh
POST_SCRIPT:=scripts/3-post.sh
CLEAN_SCRIPT:=scripts/0-clean.sh
HAMMER_CONF:=conf/cli_config.yml.sh
HAMMER_CONF_INSTALLED:=$(HOME)/.hammer/cli_config.yml
BLOCKDEV_CONF:=etc/mongod.service.d/blockdev.conf
BLOCKDEV_CONF_INSTALLED:=/etc/systemd/system/mongod.service.d/blockdev.conf

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

$(HAMMER_CONF_INSTALLED): $(HAMMER_CONF)
	./$(HAMMER_CONF) > $@

$(BLOCKDEV_CONF_INSTALLED): $(BLOCKDEV_CONF)
	install -d $(dirname $@)
	install $< $@

pre-install: .done_pre-install
.done_pre-install: $(HAMMER_CONF_INSTALLED) $(BLOCKDEV_CONF_INSTALLED) $(PRE_SCRIPT)
	./$(PRE_SCRIPT)
	touch $@

install: .done_install
.done_install: $(INSTALL_SCRIPT)
	./$(INSTALL_SCRIPT)
	touch $@

post-install: .done_post-install
.done_post-install: $(POST_SCRIPT)
	./$(POST_SCRIPT)
	touch $@

.FORCE_clean:
clean: .FORCE_clean
	./$(CLEAN_SCRIPT)
