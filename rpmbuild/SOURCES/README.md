# Building the RPM

Install `rpm-build`, then run this command from the repository root:

```sh
rpmbuild --define "_topdir $PWD/rpmbuild" -ba rpmbuild/SPECS/re-suspend.spec
```

The resulting source and binary RPMs are written below `rpmbuild/SRPMS` and
`rpmbuild/RPMS`. The package installs the hooks below `/usr/libexec/re-suspend`
and the systemd drop-ins below `/usr/lib/systemd/system`.