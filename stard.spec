Name:		stard
Version:	0.3.1
Release:	1%{?dist}
Summary:	Starmade daemon and plugin scripts

Group:		Applications/Games
License:	MIT
#URL:		
Source0:	stard.tar.gz

Provides:	perl(stard_core)
Provides:	perl(stard_lib)
Provides:	perl(stard_log)
Provides:	perl(Stard::Base)
Provides:	perl(Stard::Multiplexer)
Provides:	perl(Stard::Plugin)
Provides:	perl(Stard::Log)
Provides:	perl(Stard::Regression)
Provides:	perl(Starmade::Base)
Provides:	perl(Starmade::Chat)
Provides:	perl(Starmade::Player)
Provides:	perl(Starmade::Faction)
Provides:	perl(Starmade::Misc)
Provides:	perl(Starmade::Sector)
Provides:	perl(Starmade::Message)
Provides:	perl(Starmade::Map)
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
useradd -c "Privilege-separated starmade server" -s /bin/bash -r -d /var/starmade starmade 2> /dev/null || :
service stard stop || :

%post
for plugin in `ls /var/starmade/stard/plugins.disabled/`; do
	if [ -e /var/starmade/stard/plugins/$plugin ];then
		cp -R "/var/starmade/stard/plugins.disabled/$plugin" "/var/starmade/stard/plugins/"
		rm -rf "/var/starmade/stard/plugins.disabled/$plugin"
	fi
done
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
%config(noreplace) /etc/sysconfig/stard
%attr(755,root,root) /etc/rc.d/init.d/stard


%attr(1777,root,root) /var/starmade/spool

%defattr(644,root,root, 0755)
%dir /var/starmade/stard/bin
%dir /var/starmade/stard/lib
%attr(1770,root,root) /var/starmade/stard/spool
%attr(755,root,root) /var/starmade/stard/bin/*
%attr(755,root,root) /var/starmade/stard/lib/*
%attr(755,root,root) /var/starmade/stard/libexec/*
/var/starmade/stard/plugins/*
/var/starmade/server
%attr(755,starmade,starmade) /var/starmade/stard/plugins.disabled


%defattr(644,starmade,starmade, 0755)
%dir /var/starmade/stard/plugins
%dir /var/starmade/stard/log
%dir /var/starmade/stard


%config(noreplace) /var/starmade/stard/stard.cfg

%doc

