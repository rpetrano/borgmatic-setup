# Paths (can be overridden: make install SYSTEMD_DIR=/lib/systemd/system ...)
SYSTEMD_DIR     ?= /etc/systemd/system
BORG_DIR        ?= /etc/borgmatic.d
BIN_DIR         ?= /usr/local/bin

# systemd units / timers
SYSTEMD_SERVICES = \
	systemd/borgmatic@.service \
	systemd/backup-notify@.service

# override drop-in for borgmatic-check@.service
BORG_CHECK_OVERRIDE = systemd/borgmatic-check@.service

SYSTEMD_TIMERS = \
	systemd/borgmatic@archives.img.timer \
	systemd/borgmatic@crypt.img.timer \
	systemd/borgmatic@root.timer \
	systemd/borgmatic@vaultwarden.timer \
	systemd/borgmatic@win10_c.timer \
	systemd/borgmatic@win10_d.timer \
	systemd/borgmatic@immich.timer \
	systemd/borgmatic-check@check.timer

# borgmatic configs
BORG_CONFIGS = \
	borgmatic/archives.img.yaml \
	borgmatic/crypt.img.yaml \
	borgmatic/root.yaml \
	borgmatic/vaultwarden.yaml \
	borgmatic/win10_c.yaml \
	borgmatic/win10_d.yaml \
	borgmatic/immich.yaml

BORG_COMMON = \
	borgmatic/common/local_backup.yaml \
	borgmatic/common/commands_image_mount.yaml \
	borgmatic/common/commands_mount.yaml

# scripts
BIN_SCRIPTS = \
	bin/borgmatic-wrapper.sh \
	bin/borgmatic-check-wrapper.sh \
	bin/backup-notify.sh

# Default target: show help
.PHONY: help
help:
	@echo "Targets:"
	@echo "  install          - Install all systemd units, borgmatic configs, scripts"
	@echo "  install-systemd  - Install only systemd unit/timer files"
	@echo "  install-borg     - Install only borgmatic YAML configs"
	@echo "  install-bin      - Install only scripts"
	@echo "  reload           - systemctl daemon-reload"
	@echo "  enable           - Enable & start timers"
	@echo "  disable          - Disable & stop timers"

# --- Install targets -------------------------------------------------------

.PHONY: install
install: install-systemd install-borg install-bin reload

.PHONY: install-systemd
install-systemd: $(SYSTEMD_SERVICES) $(SYSTEMD_TIMERS) $(BORG_CHECK_OVERRIDE)
	@echo "Installing systemd services to $(SYSTEMD_DIR)"
	@for f in $(SYSTEMD_SERVICES); do \
		echo "  install $$f -> $(SYSTEMD_DIR)/$$(basename $$f)"; \
		install -Dm644 "$$f" "$(SYSTEMD_DIR)/$$(basename $$f)"; \
	done

	@echo "Installing borgmatic-check@.service as symlink + drop-in override"
	@echo "  symlink $(SYSTEMD_DIR)/borgmatic-check@.service -> $(SYSTEMD_DIR)/borgmatic@.service"
	@ln -sfn "borgmatic@.service" "$(SYSTEMD_DIR)/borgmatic-check@.service"

	@override_dir="$(SYSTEMD_DIR)/borgmatic-check@check.service.d"; \
	echo "  install $(BORG_CHECK_OVERRIDE) -> $$override_dir/override.conf"; \
	install -Dm644 "$(BORG_CHECK_OVERRIDE)" "$$override_dir/override.conf"

	@echo "Installing systemd timers to $(SYSTEMD_DIR)"
	@for f in $(SYSTEMD_TIMERS); do \
		echo "  install $$f -> $(SYSTEMD_DIR)/$$(basename $$f)"; \
		install -Dm644 "$$f" "$(SYSTEMD_DIR)/$$(basename $$f)"; \
	done

.PHONY: install-borg
install-borg: $(BORG_CONFIGS) $(BORG_COMMON)
	@echo "Installing borgmatic configs to $(BORG_DIR)"
	@for f in $(BORG_CONFIGS); do \
		echo "  install $$f -> $(BORG_DIR)/$$(basename $$f)"; \
		install -Dm644 "$$f" "$(BORG_DIR)/$$(basename $$f)"; \
	done
	@for f in $(BORG_COMMON); do \
		dest_dir="$(BORG_DIR)/common"; \
		echo "  install $$f -> $$dest_dir/$$(basename $$f)"; \
		install -Dm644 "$$f" "$$dest_dir/$$(basename $$f)"; \
	done

.PHONY: install-bin
install-bin: $(BIN_SCRIPTS)
	@echo "Installing scripts to $(BIN_DIR)"
	@for f in $(BIN_SCRIPTS); do \
		echo "  install $$f -> $(BIN_DIR)/$$(basename $$f)"; \
		install -Dm755 "$$f" "$(BIN_DIR)/$$(basename $$f)"; \
	done

.PHONY: reload
reload:
	@echo "Reloading systemd daemon"
	@systemctl daemon-reload

# --- Timer management ------------------------------------------------------

.PHONY: enable
enable:
	@echo "Enabling and starting timers"
	@systemctl enable --now \
		borgmatic@archives.img.timer \
		borgmatic@crypt.img.timer \
		borgmatic@root.timer \
		borgmatic@vaultwarden.timer \
		borgmatic@win10_c.timer \
		borgmatic@win10_d.timer \
		borgmatic@immich.timer \
		borgmatic-check@check.timer || true

.PHONY: disable
disable:
	@echo "Disabling and stopping timers"
	@systemctl disable --now \
		borgmatic@archives.img.timer \
		borgmatic@crypt.img.timer \
		borgmatic@root.timer \
		borgmatic@vaultwarden.timer \
		borgmatic@win10_c.timer \
		borgmatic@win10_d.timer \
		borgmatic@immich.timer \
		borgmatic-check@check.timer || true

