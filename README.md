# Jira Data Center SELinux Policy

SELinux policy module for Atlassian Jira Data Center on RHEL/CentOS 9.

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

## Monitoring

```bash
make audit                                           # recent denials
sudo tail -f /var/log/audit/audit.log | grep jira   # live monitoring
```

If new denials appear after a Jira upgrade, use `audit2allow` to identify required additions:

```bash
sudo ausearch -m avc -ts recent | audit2allow
```

Review suggestions carefully before applying.

## Troubleshooting

**Module not loaded** - run `make install`

**Wrong file contexts** - run `make relabel` (uses `-RF` to force)

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
