# Makefile for JIRA SELinux Policy Module

MODULE  = jira
VERSION = 1.0.0

POLICY_FILES = $(MODULE).te $(MODULE).fc
PP_FILE      = $(MODULE).pp
MOD_FILE     = $(MODULE).mod

.PHONY: all preflight check clean install remove relabel verify audit help

all: $(PP_FILE)

preflight:
	@echo "Preflight checks:"
	@grep -qE "release 9" /etc/redhat-release 2>/dev/null || \
		echo "  WARNING: Tested on RHEL/CentOS 9 - your OS: $$(cat /etc/redhat-release 2>/dev/null || echo unknown)"
	@getenforce &>/dev/null || (echo "  ERROR: SELinux not available" && exit 1)
	@echo "  SELinux:      $$(getenforce)"
	@for t in checkmodule semodule_package semodule ausearch restorecon; do \
		command -v $$t &>/dev/null || (echo "  ERROR: missing $$t - run: dnf install -y selinux-policy-devel make" && exit 1); \
	done
	@echo "  Tools:        OK"
	@test -d /opt/atlassian/jira                  && echo "  Jira install: found" || echo "  WARNING: /opt/atlassian/jira not found"
	@test -d /var/atlassian/application-data/jira && echo "  Jira home:    found" || echo "  WARNING: /var/atlassian/application-data/jira not found"
	@echo ""
	@echo "  Ready. Run: make check && make install && make relabel"

check: $(POLICY_FILES)
	@echo "Checking policy syntax..."
	@checkmodule -M -m -o /tmp/$(MODULE).mod $(MODULE).te
	@rm -f /tmp/$(MODULE).mod
	@echo "  OK"

$(PP_FILE): $(POLICY_FILES)
	@echo "Building policy module..."
	@checkmodule -M -m -o $(MOD_FILE) $(MODULE).te
	@semodule_package -o $(PP_FILE) -m $(MOD_FILE) -f $(MODULE).fc
	@echo "  Built: $(PP_FILE)"

install: $(PP_FILE)
	@echo "Installing policy module..."
	@sudo semodule -i $(PP_FILE)
	@echo "  Loaded: $$(sudo semodule -l | grep $(MODULE))"

remove:
	@echo "Removing policy module..."
	@sudo semodule -r $(MODULE) 2>/dev/null && echo "  Removed" || echo "  Not loaded"

relabel: install
	@echo "Relabeling filesystem..."
	@sudo restorecon -RFv /opt/atlassian/jira 2>/dev/null | grep -c "Relabeled" | xargs -I{} echo "  Relabeled {} files under /opt/atlassian/jira" || true
	@sudo restorecon -RFv /var/atlassian/application-data/jira 2>/dev/null | grep -c "Relabeled" | xargs -I{} echo "  Relabeled {} files under /var/atlassian/application-data/jira" || true
	@echo "  Done"

verify:
	@echo "Module:        $$(sudo semodule -l | grep $(MODULE) || echo 'NOT LOADED')"
	@echo "Install dir:   $$(ls -ldZ /opt/atlassian/jira 2>/dev/null | awk '{print $$5}' || echo 'not found')"
	@echo "Home dir:      $$(ls -ldZ /var/atlassian/application-data/jira 2>/dev/null | awk '{print $$5}' || echo 'not found')"
	@echo "Service:       $$(systemctl is-active jira 2>/dev/null || echo 'unknown')"
	@echo "Java domain:   $$(ps -eZ 2>/dev/null | grep ' java$$\| java ' | awk '{print $$1}' | head -1 || echo 'not running')"

audit:
	@echo "Recent AVC denials:"
	@sudo ausearch -m avc -ts recent 2>/dev/null | grep -i "jira\|atlassian" || echo "  none"

clean:
	@echo "Cleaning..."
	@rm -f $(MODULE).mod $(MODULE).pp $(MODULE).if
	@echo "  Done"

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "  preflight   check system prerequisites"
	@echo "  check       verify policy syntax"
	@echo "  all         build jira.pp"
	@echo "  install     build and load the module"
	@echo "  relabel     install and relabel filesystem"
	@echo "  verify      show module, contexts, and service status"
	@echo "  audit       show recent SELinux denials"
	@echo "  remove      unload the module"
	@echo "  clean       remove build artifacts"
