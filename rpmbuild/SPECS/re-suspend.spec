Name:           re-suspend
Version:        0.1.0
Release:        1%{?dist}
Summary:        Re-suspend once after an RTC wakeup
License:        MIT
URL:            https://github.com/suikan4github/re-suspend
BuildArch:      noarch

Requires:       systemd
Requires:       util-linux
Requires(post): systemd
Requires(postun): systemd

Source0:        re-suspend-pre.sh
Source1:        re-suspend-post.sh
Source2:        re-suspend-suspend.conf
Source3:        re-suspend-suspend-then-hibernate.conf
Source4:        README.md
Source5:        LICENSE

%description
Install systemd hooks that wake the system with an RTC timer and suspend it
again once. A manual wake before the timer expires cancels the second suspend.

%prep

%build

%install
rm -rf %{buildroot}

install -D -m 0755 %{SOURCE0} %{buildroot}%{_libexecdir}/re-suspend/re-suspend-pre.sh
install -D -m 0755 %{SOURCE1} %{buildroot}%{_libexecdir}/re-suspend/re-suspend-post.sh
install -D -m 0644 %{SOURCE2} \
    %{buildroot}%{_prefix}/lib/systemd/system/systemd-suspend.service.d/re-suspend.conf
install -D -m 0644 %{SOURCE3} \
    %{buildroot}%{_prefix}/lib/systemd/system/systemd-suspend-then-hibernate.service.d/re-suspend.conf
install -D -m 0644 %{SOURCE4} %{buildroot}%{_docdir}/%{name}/README.md
install -D -m 0644 %{SOURCE5} %{buildroot}%{_docdir}/%{name}/LICENSE

%post
systemctl daemon-reload >/dev/null 2>&1 || :

%postun
systemctl daemon-reload >/dev/null 2>&1 || :

%files
%doc %{_docdir}/%{name}/README.md
%license %{_docdir}/%{name}/LICENSE
%{_libexecdir}/re-suspend/re-suspend-pre.sh
%{_libexecdir}/re-suspend/re-suspend-post.sh
%{_prefix}/lib/systemd/system/systemd-suspend.service.d/re-suspend.conf
%{_prefix}/lib/systemd/system/systemd-suspend-then-hibernate.service.d/re-suspend.conf

%changelog
* Tue Sep 15 2026 re-suspend maintainers <noreply@example.invalid> - 0.1.0-1
- Initial RPM package.