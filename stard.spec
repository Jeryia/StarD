

#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
#1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
#2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
#3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Name:		stard
Version:	0.0.9
Release:	1%{?dist}
Summary:	Starmade daemon and plugin scripts

Group:		Applications/Games
License:	GPL
#URL:		
Source0:	stard.tar.gz

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

* Sat Sep 19 2015 Jeryia <johndoe@gmail.com>
- v0.0.9
- Standalone version now compiles and seems to run ok. Still considered experimental.
- Pulled some self healing bits back into the script (now will download starmade for you, and set the keys if they are not set).
- Added feature to set the current working directory of all called plugin actions to be the plugin's directory.
- Daemon configuration is now stored in /etc/sysconfig (red hat) or /etc/default (debian)
- Reccommending this version as alpha release 0.1.0.
* Wed Sep 9 2015 Jeryia <johndoe@gmail.com>
- v0.0.2
- Regression testing fully added.
- much refactoring
* Mon Sep 7 2015 Jeryia <johndoe@gmail.com>
- rpm first built
