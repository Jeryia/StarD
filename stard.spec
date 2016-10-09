Name:		stard
Version:	0.2.1
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



%changelog

* Fri Jul 22 2016 Jeryia <johndoe@gmail.com>
- v0.2.1
- Fixed issues with stard-multiplexer being unable to launch serverEvents correctly
- Fixed logging issues with the plugin commands.
- Allow the loading and unloading of multiple plugins at once.
- !plugin list now lists plugins in alphabetical order.
* Wed Jul 20 2016 Jeryia <johndoe@gmail.com>
- v0.2.0
- Moved to new plugin loading model:
  - plugins only need to be in the plugins directory to be loaded
  - plugins can now be loaded and unloaded via the in game command !plugin
  - unloaded plugins go in plugins.disabled
  - all plugins now start in plugins.disabled except for the Base plugin as it provides the !plugin command
  - Plugins now can have a info.txt file associated with them that contains information that !plugin can query for admins to know what a plugin is before loading it
- Add new plugins(these are all disabled by default):
  - GodlyAdmins - admins get god mode and invisability on login
  - Bounty - allows players to put up and collect on bounties on other player's heads.
  - LastLogin - allows players to check ho long ago a player last logged in.
- Added the stard_map library. This library allows spawning of stations/ships at specific coordinates from an ini file.
- General polishing of code. (see github commits for details)
- Fixed an issue with updating to newer versions of starmade

* Sun Jan 24 2016 Jeryia <johndoe@gmail.com>
- v0.1.0
- Support for multi-line messages with chat commands
- Update support for StarMade via service stard update-sm
- Ability to backup and restore entire setup via service stard backup and service stard restore
- Stuck now teleports a player 300m instead of to an ajacent sector.
- Workaround so that StarMade no longer takes up an entire cpu at all times...
- fixed up log rotation
- added new action stard_countdown
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
