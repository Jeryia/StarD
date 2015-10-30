Name:		stard
Version:	0.0.13
Release:	1%{?dist}
Summary:	Starmade daemon and plugin scripts

Group:		Applications/Games
License:	GPL
#URL:		
Source0:	stard.tar.gz

Provides:	perl(stard_core)
Provides:	perl(stard_lib)
Provides:	perl(stard_log)
BuildArch: 	noarch
BuildRequires:	bash perl
Requires:	bash perl wget rsync 

%description
Tools for running a starmade daemon and plugins for managing it

%prep
%setup -q


%build
./configure
make


%install
mkdir %{buildroot}/var
mkdir -p %{buildroot}/etc/rc.d/init.d
mkdir -p %{buildroot}/usr/sbin
mkdir -p %{buildroot}/usr/lib/systemd/system/
mkdir -p %{buildroot}/etc/sysconfig
ln -s %{buildroot}/etc/rc.d/init.d %{buildroot}/etc/init.d


make install DESTDIR=%{buildroot}
rm %{buildroot}/etc/init.d

%pre
useradd -c "Privilege-separated starmade server" -s /bin/bash -r -d /var/starmade/starmade 2> /dev/null || :
service stard stop || :

%post
/usr/bin/systemctl --system daemon-reload
if [ $1 -ge 1 ] ; then
	systemctl is-enabled stard > /dev/null && /usr/bin/systemctl start stard || :
fi

%preun
/usr/bin/systemctl stop stard

%postun
/usr/bin/systemctl --system daemon-reload

%files
%defattr(644,starmade,starmade, 0755)
%attr(0555,root,root) /usr/sbin/stard
%attr(0555,root,root) /usr/sbin/stard-backup
%attr(0555,root,root) /usr/sbin/stard-stop
%config(noreplace) /etc/sysconfig/stard
%attr(755,root,root) /etc/rc.d/init.d/stard


%attr(1777,root,root) /var/starmade/spool
%attr(-,root,root) /var/starmade/server

%defattr(644,root,root, 0755)
%dir /var/starmade/stard/bin
%dir /var/starmade/stard/lib
%attr(1770,root,root) /var/starmade/stard/spool
%attr(755,root,root) /var/starmade/stard/bin/*
%attr(755,root,root) /var/starmade/stard/lib/*
%attr(755,starmade,starmade) /var/starmade/stard/plugins.sample


%defattr(644,starmade,starmade, 0755)
%dir /var/starmade/stard/plugins
%dir /var/starmade/stard/log

%config(noreplace) /var/starmade/stard/stard.cfg

%doc



%changelog
* Thu Oct 29 2015 Jeryia <johndoe@gmail.com>
- v0.0.13
- Permission setting is less strict in starmade server directory
- Fixing Permissions on plugins who have them set incorrectly
* Sun Oct 18 2015 Jeryia <johndoe@gmail.com>
- v0.0.12
- Logging has been fixed to report the real time of the event instead of the time the server started
- The Base plugin is now loaded by default.
* Fri Oct 16 2015 Jeryia <johndoe@gmail.com>
- v0.0.11
- Install scripts now create required directories, since git deletes them (as they are empty
* Tue Oct 13 2015 Jeryia <johndoe@gmail.com>
- v0.0.10
- Standalone version fully tested and ready for release
- Modified libraries to be more like standard perl libraries
- Fixed a bug where this would not catch entities unfactioning
* Sat Sep 19 2015 Jeryia <johndoe@gmail.com>
- v0.0.9
- Standalone version now compiles and seems to run ok. Still considered experimental.
- Pulled some self healing bits back into the script (now will download starmade for you, and set the keys if they are not set).
- Added feature to set the current working directory of all called plugin actions to be the plugin's directory.
- Daemon configuration is now stored in /etc/sysconfig (red hat) or /etc/default (debian)
* Wed Sep 9 2015 Jeryia <johndoe@gmail.com>
- v0.0.2
- Regression testing fully added.
- much refactoring
* Mon Sep 7 2015 Jeryia <johndoe@gmail.com>
- rpm first built
