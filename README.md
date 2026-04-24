# Jira Data Center SELinux Policy

SELinux policy module for Atlassian Jira Data Center on RHEL/CentOS 9.

<img src="assets/jira-logo.png" alt="Jira" height="80" />     <img src="assets/selinux-logo.png" alt="SELinux" height="80" />     <img src="assets/redhat-logo.png" alt="Red Hat" height="80" />

## Requirements

```bash
sudo dnf install -y selinux-policy-devel make
```

SELinux must be in Enforcing or Permissive mode (`getenforce`).

## Installation

```bash
make preflight       # check prerequisites
make check           # verify policy syntax
make install         # build and load the module
make relabel         # apply file contexts
make verify          # confirm everything is correct
```

## Systemd Service

```bash
sudo cp jira.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now jira
```

## Make Targets

| Target | Description |
|--------|-------------|
| `preflight` | Check system prerequisites |
| `check` | Verify policy syntax |
| `all` | Build `jira.pp` |
| `install` | Build and load the module |
| `relabel` | Install and relabel filesystem |
| `verify` | Check module, contexts, and service |
| `audit` | Show recent SELinux denials |
| `remove` | Unload the module |
| `clean` | Remove build artifacts |

## Configuration

| Path | Context |
|------|---------|
| `/opt/atlassian/jira` | `jira_install_t` |
| `/var/atlassian/application-data/jira` | `jira_home_t` |
| `/var/atlassian/application-data/jira/logs` | `jira_log_t` |
| `/tmp/jira.*`, `/var/tmp/jira.*` | `jira_tmp_t` |
| `jre/bin/java` (bundled or system) | `jira_exec_t` |

Ports: HTTP `8080`, Shutdown `8005`, eazyBI `3801`.

To change paths or ports, edit `jira.fc` / `jira.te` and re-run `make install relabel`.

## Monitoring and Troubleshooting

Check for denials from the running Jira process:

```bash
make audit | grep $(pgrep -f 'jira.*java' | head -1) | audit2allow
```

Check all recent SELinux denials system-wide:

```bash
ausearch -m avc -ts recent | audit2allow
```

Review SELinux denial details via setroubleshoot:

```bash
systemctl status setroubleshootd
```

If `audit2allow` reports rules marked `"This avc is allowed in the current policy"`, these are cached entries from before a policy update. Only rules without that marker require action.

**Module not loaded** - run `make install`

**Wrong file contexts** - run `make relabel`

**Service fails** - check `journalctl -xeu jira.service` and `make audit`

**Policy syntax error** - run `make check`

## Files

| File | Purpose |
|------|---------|
| `jira.te` | Type enforcement - domains and permissions |
| `jira.fc` | File contexts - filesystem labeling |
| `jira.if` | Interfaces - for use by other policies |
| `jira.service` | Systemd service unit |
| `Makefile` | Build and management |

## Notes

This policy was developed and tested with Jira Data Center using MySQL. PostgreSQL database access rules are not included. If you use PostgreSQL, you will need to add the appropriate SELinux permissions for `postgresql_port_t` (default port 5432) in `jira.te`.

Atlassian's official stance is to either disable SELinux or thoroughly validate custom policies (see [Run Jira as a systemd service on Linux](https://support.atlassian.com/jira/kb/run-jira-server-or-data-center-as-a-systemd-service-on-linux/)). This policy will likely require customization for your environment. Feel free to fork and adapt.
