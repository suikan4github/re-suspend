# re-suspend RPM

The RPM is the supported installation method. It installs the hooks below
`/usr/libexec/re-suspend` and the systemd drop-ins below
`/usr/lib/systemd/system`.

Install the built RPM with:

```sh
sudo dnf install ./rpmbuild/RPMS/noarch/re-suspend-*.rpm
```

Remove it with:

```sh
sudo dnf remove re-suspend
```

## Building

Install `rpm-build`, then run this command from the repository root:

```sh
rpmbuild --define "_topdir $PWD/rpmbuild" -ba rpmbuild/SPECS/re-suspend.spec
```

The resulting source and binary RPMs are written below `rpmbuild/SRPMS` and
`rpmbuild/RPMS`.