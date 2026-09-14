# re-suspend

`re-suspend` makes a system suspend one more time after it wakes from an RTC
wake timer. This could be the problem that CPU fans continue running even after
the system has suspended.

The project is distributed as an RPM. 

## How it works

When a suspend begins, the `systemd-suspend.service` or
`systemd-suspend-then-hibernate.service` drop-in runs the pre-hook. The hook:

1. Records the suspend mode and an RTC wake deadline.
2. Programs an RTC wake timer for 30 seconds.
3. Lets systemd perform the requested suspend normally.

After the system wakes, the post-hook compares the current time with the
recorded deadline:

- A wake before the deadline is treated as a manual wake. The RTC alarm is
  cancelled and no second suspend is scheduled.
- A wake at or after the deadline is treated as an RTC wake. A one-shot
  systemd timer schedules the same suspend mode again after five seconds.
- The second suspend does not schedule another RTC wake. Its final wake cleans
  up the state file.

The package does not add a new long-running service. It installs drop-ins for
existing systemd services and reloads systemd after installation or removal.

## Requirements

- Fedora Workstation or Fedora Atomic Desktop
- systemd
- util-linux (`rtcwake`)
- root privileges for installation and removal

## Build

### Using the repository build script

`build.sh` creates a temporary toolbox, installs `rpm-build` in it, and builds
both the binary RPM and the source RPM with `rpmbuild -ba`:

```sh
./build.sh
```

The build artifacts are written to:

```text
rpmbuild/RPMS/noarch/re-suspend-<version>-<release>.<distribution>.noarch.rpm
rpmbuild/SRPMS/re-suspend-<version>-<release>.<distribution>.src.rpm
```

The script requires Toolbx (`toolbox`) and Podman support. The temporary
container is removed when the script exits.

### Building directly

If `rpm-build` is installed on the host, build from the repository root with:

```sh
rpmbuild --define "_topdir $PWD/rpmbuild" -ba \
  rpmbuild/SPECS/re-suspend.spec
```

## Install

Build the RPM, then run this command from the repository root. It detects an
Atomic Desktop host by checking for `rpm-ostree`.

```sh
RPM_FILE=$(printf '%s\n' ./rpmbuild/RPMS/noarch/re-suspend-*.rpm)

if [ -n "$(command -v rpm-ostree 2>/dev/null)" ]; then
  sudo rpm-ostree install "$RPM_FILE"
else
  sudo dnf install "$RPM_FILE"
fi
```
> [!NOTE]
> In the case of Fedora Atomic Desktop, a reboot is required to apply the
> installed deployment.

The RPM scriptlet runs `systemctl daemon-reload` after installation. If the
reload cannot be performed, installation continues with a warning. On Atomic
Desktop, the reboot applies the installed deployment; on other systems, run
`systemctl daemon-reload` manually if needed.

## Verify the installation

Check the installed files and the merged systemd configuration:

```sh
rpm -ql re-suspend
systemctl cat systemd-suspend.service
systemctl cat systemd-suspend-then-hibernate.service
```

The relevant installed paths are:

```text
/usr/libexec/re-suspend/re-suspend-pre.sh
/usr/libexec/re-suspend/re-suspend-post.sh
/usr/lib/systemd/system/systemd-suspend.service.d/re-suspend.conf
/usr/lib/systemd/system/systemd-suspend-then-hibernate.service.d/re-suspend.conf
```

The runtime state is stored at `/run/re-suspend-state` and is removed after a
normal final wake or when a manual wake cancels the cycle.

## Remove

To remove the package, use the following command:
```sh
if [ -n "$(command -v rpm-ostree 2>/dev/null)" ]; then
  sudo rpm-ostree uninstall re-suspend
else
  sudo dnf remove re-suspend
fi
```
> [!NOTE]
> In the case of Fedora Atomic Desktop, a reboot is required to apply the
> removal of the package.


After removal, systemd no longer loads the package drop-ins. A pending
one-shot re-suspend should be stopped before removal if necessary.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
