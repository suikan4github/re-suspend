# re-suspend RPM

## Purpose

This package installs systemd drop-ins that briefly wake a suspended system
with an RTC timer and then suspend it again. A manual wake before the timer
expires cancels the second suspend.

The RPM installs the hooks below `/usr/libexec/re-suspend` and the drop-ins
below `/usr/lib/systemd/system`. It does not add or enable a new long-running
service.

The drop-ins are package-owned vendor configuration. This is why they are
placed below `/usr/lib` instead of `/etc`, which is reserved for local
administrator overrides.

## Install

Install from the directory containing the RPM. This detects an Atomic Desktop
host by checking for `rpm-ostree`:

```sh
RPM_FILE=$(printf '%s\n' ./re-suspend-*.rpm)

if [ -n "$(command -v rpm-ostree 2>/dev/null)" ]; then
	sudo rpm-ostree install "$RPM_FILE"
	systemctl reboot
else
	sudo dnf install "$RPM_FILE"
fi
```

The `if` branch is intentional: Workstation uses `dnf`, while Atomic Desktop
stages the package into an immutable deployment with `rpm-ostree` and needs a
reboot before the change is active.

## Verify

```sh
rpm -ql re-suspend
systemctl cat systemd-suspend.service
systemctl cat systemd-suspend-then-hibernate.service
```

## Remove

Use the same environment detection when removing the package:

```sh
if [ -n "$(command -v rpm-ostree 2>/dev/null)" ]; then
	 sudo rpm-ostree uninstall re-suspend
	 sudo systemctl reboot
else
	 sudo dnf remove re-suspend
fi
```

If a one-shot `re-suspend-once` job is already pending, stop it first:

```sh
sudo systemctl stop re-suspend-once.timer re-suspend-once.service 2>/dev/null || true
```

The package runs `systemctl daemon-reload` after installation and removal. If
systemd cannot be reloaded in the current environment, it prints a warning;
the package operation continues and a reboot or manual reload applies the
drop-ins.